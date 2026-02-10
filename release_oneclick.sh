#!/bin/bash

#
# release_oneclick.sh
# ScreenPresenter 一键发布脚本（交互式/非交互式）
#
# 用法:
#   ./release_oneclick.sh                # 交互式（会提示输入版本）
#   ./release_oneclick.sh 1.0.5          # 指定版本
#   ./release_oneclick.sh 1.0.5 --yes    # 全自动确认
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_step() { echo -e "${CYAN}▶️  $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

CHANGELOG_PATH="docs/CHANGELOG.md"
APPCAST_PATH="appcast.xml"

AUTO_YES=0
VERSION=""

for arg in "$@"; do
    case "$arg" in
    --yes|-y)
        AUTO_YES=1
        ;;
    --help|-h)
        cat <<'EOF'
用法:
  ./release_oneclick.sh [version] [--yes]

示例:
  ./release_oneclick.sh 1.0.5
  ./release_oneclick.sh 1.0.5 --yes
EOF
        exit 0
        ;;
    *)
        if [ -z "$VERSION" ]; then
            VERSION="$arg"
        else
            log_error "未知参数: $arg"
            exit 1
        fi
        ;;
    esac
done

confirm() {
    local prompt="$1"
    if [ "$AUTO_YES" -eq 1 ]; then
        return 0
    fi
    read -r -p "$prompt [Y/n]: " response
    case "$response" in
    ""|[Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
    esac
}

if [ -z "$VERSION" ]; then
    if [ "$AUTO_YES" -eq 1 ]; then
        log_error "--yes 模式下必须传入版本号"
        exit 1
    fi
    read -r -p "请输入要发布的版本号（例如 1.0.5）: " VERSION
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "版本号格式不正确: $VERSION（期望 x.y.z）"
    exit 1
fi

if git rev-parse "refs/tags/$VERSION" >/dev/null 2>&1; then
    log_error "Tag 已存在: $VERSION"
    exit 1
fi

LAST_TAG=$(git tag --list --sort=-v:refname | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1 || true)
if [ -n "$LAST_TAG" ]; then
    RANGE="$LAST_TAG..HEAD"
else
    RANGE="HEAD"
fi

log_info "发布版本: $VERSION"
if [ -n "$LAST_TAG" ]; then
    log_info "变更范围: $RANGE"
else
    log_info "未检测到历史版本 tag，将基于当前提交生成说明"
fi

build_commit_bullets() {
    if [ "$RANGE" = "HEAD" ]; then
        git log --no-merges --pretty=format:'- %s' -n 30
    else
        git log --no-merges --pretty=format:'- %s' "$RANGE"
    fi
}

prepend_changelog_section() {
    if [ ! -f "$CHANGELOG_PATH" ]; then
        echo "# Changelog" > "$CHANGELOG_PATH"
    fi

    if grep -q "^## $VERSION$" "$CHANGELOG_PATH"; then
        log_warning "CHANGELOG 已存在 $VERSION 条目，跳过自动插入"
        return 0
    fi

    local bullets
    bullets="$(build_commit_bullets || true)"
    if [ -z "$bullets" ]; then
        bullets="- 常规维护与稳定性优化"
    fi

    local tmp
    tmp="$(mktemp)"
    {
        head -n 1 "$CHANGELOG_PATH"
        echo ""
        echo "## $VERSION"
        echo ""
        echo "### 改动"
        echo ""
        echo "$bullets"
        echo ""
        tail -n +2 "$CHANGELOG_PATH"
    } > "$tmp"
    mv "$tmp" "$CHANGELOG_PATH"
    log_success "已自动插入 CHANGELOG 条目: $VERSION"
}

extract_changelog_bullets() {
    awk "/^## $VERSION$/{flag=1;next}/^## /{flag=0}flag" "$CHANGELOG_PATH" | \
    sed -n 's/^- //p'
}

escape_xml() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    echo "$text"
}

update_appcast_description() {
    if [ ! -f "$APPCAST_PATH" ]; then
        log_warning "未找到 $APPCAST_PATH，跳过描述更新"
        return 0
    fi

    local bullets_raw
    bullets_raw="$(extract_changelog_bullets)"
    if [ -z "$bullets_raw" ]; then
        bullets_raw="$(build_commit_bullets || true)"
        bullets_raw="$(echo "$bullets_raw" | sed -n 's/^- //p')"
    fi

    local cdata_body=""
    cdata_body+="                <h2>🚀 ScreenPresenter $VERSION</h2>"$'\n'
    cdata_body+="                <p>本次更新包含以下改动：</p>"$'\n'
    cdata_body+=$'\n'
    cdata_body+="                <h3>✨ 更新内容</h3>"$'\n'
    cdata_body+="                <ul>"$'\n'

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        local escaped
        escaped="$(escape_xml "$line")"
        cdata_body+="                    <li>${escaped}</li>"$'\n'
    done <<< "$bullets_raw"
    cdata_body+="                </ul>"

    local cdata_tmp
    cdata_tmp="$(mktemp)"
    printf "%s\n" "$cdata_body" > "$cdata_tmp"

    local tmp
    tmp="$(mktemp)"
    awk '
        FNR == NR {
            cdata = cdata $0 ORS
            next
        }
        BEGIN {
            in_cdata = 0
            replaced = 0
        }
        {
            if (!replaced && $0 ~ /<!\[CDATA\[/) {
                print "                <![CDATA["
                printf "%s", cdata
                in_cdata = 1
                replaced = 1
                next
            }
            if (in_cdata) {
                if ($0 ~ /\]\]>/) {
                    print "                ]]>"
                    in_cdata = 0
                }
                next
            }
            print
        }
    ' "$cdata_tmp" "$APPCAST_PATH" > "$tmp"
    mv "$tmp" "$APPCAST_PATH"
    rm -f "$cdata_tmp"

    # 提前更新版本字段；release.sh 会在发布时再次写入最终 build/signature/download 链接
    sed -i '' "s|<title>Version [^<]*</title>|<title>Version $VERSION</title>|g" "$APPCAST_PATH"
    sed -i '' "s|<sparkle:shortVersionString>[^<]*</sparkle:shortVersionString>|<sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>|g" "$APPCAST_PATH"

    log_success "已更新 appcast 描述与版本标题"
}

log_step "预处理发布说明（CHANGELOG + appcast 描述）..."
prepend_changelog_section
update_appcast_description

if ! confirm "即将自动执行：git add/commit、打 tag、运行 ./release.sh ${VERSION}，是否继续？"; then
    log_warning "用户取消发布"
    exit 0
fi

log_step "提交准备版本改动..."
git add -A
if ! git diff --cached --quiet; then
    git commit -m "release: prepare $VERSION"
    log_success "已提交: release: prepare $VERSION"
else
    log_warning "当前无可提交改动，跳过 prepare commit"
fi

log_step "创建 tag: $VERSION"
git tag -a "$VERSION" -m "Release $VERSION"
log_success "Tag 创建完成: $VERSION"

log_step "执行正式发布脚本 ./release.sh $VERSION"
./release.sh "$VERSION"

log_step "提交发布产物元数据..."
git add -A
if ! git diff --cached --quiet; then
    git commit -m "release: finalize $VERSION metadata"
    log_success "已提交: release: finalize $VERSION metadata"
else
    log_warning "发布后无新增改动，跳过 finalize commit"
fi

echo ""
echo "=========================================="
log_success "发布流程完成: $VERSION"
echo "=========================================="
echo "建议检查:"
echo "  1) git show --no-patch --decorate $VERSION"
echo "  2) appcast.xml 版本、签名、download URL"
echo "  3) GitHub Release 页面与仓库 raw appcast"
echo ""
