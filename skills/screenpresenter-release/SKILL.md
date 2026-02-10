---
name: screenpresenter-release
description: 用于发布 ScreenPresenter 新版本（生成/更新 CHANGELOG、更新 appcast、打 tag、执行发布脚本、创建 GitHub Release）的标准化流程。用户提出“发布 x.y.z”“准备发版”“走一遍 release 流程”时使用。
---

# ScreenPresenter Release Skill

## 适用场景

- 用户要求发布新版本（例如 `1.0.5`）
- 用户要求一键完成发版流程
- 用户要求同步更新 changelog / appcast / GitHub Release

## 执行入口

- 交互式：
  - `./release_oneclick.sh`
- 一键非交互：
  - `./release_oneclick.sh <version> --yes`
  - 例：`./release_oneclick.sh 1.0.5 --yes`

## 脚本行为（自动完成）

1. 基于上一个 tag 到 `HEAD` 的提交，自动补充 `docs/CHANGELOG.md` 当前版本条目（若缺失）。
2. 用 changelog 当前版本内容更新 `appcast.xml` 的描述与版本标题（签名与下载链接由后续步骤写入）。
3. `git add -A` 并提交 `release: prepare <version>`（有改动才提交）。
4. 创建本地 tag：`<version>`。
5. 执行 `./release.sh <version>`（构建、签名、更新 appcast、创建 GitHub Release）。
6. 对发布后变更做收尾提交：`release: finalize <version> metadata`（有改动才提交）。

## 前置条件

- 已安装并登录 `gh`（GitHub CLI）
- 已安装 Sparkle 工具（`sign_update`）
- 具备发布权限

## 验证项

- `git show --no-patch --decorate <version>`
- `appcast.xml` 中 `sparkle:shortVersionString`、`sparkle:version`、`enclosure url/length/edSignature`
- GitHub Release 页面与仓库内 raw appcast：`https://raw.githubusercontent.com/HapticTide/ScreenPresenter/main/appcast.xml`

## 注意事项

- 本流程不会自动执行 `git push`。
- 若目标 tag 已存在，脚本会直接失败并停止。
