#!/usr/bin/env ruby
# 添加缺失的 Swift 文件到 Xcode 项目

require 'xcodeproj'

project_path = 'DemoConsole.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 获取主 target
target = project.targets.first

# 定义需要添加的文件（相对于 DemoConsole 目录）
files_to_add = {
  'Core/Rendering' => ['FPSTracker.swift', 'GPUMonitor.swift'],
  'Core/Utilities' => ['Logger.swift'],
  'Core/DeviceSource' => ['DeviceSource.swift', 'QuickTimeDeviceSource.swift', 'ScrcpyDeviceSource.swift'],
  'Core/Preferences' => ['UserPreferences.swift'],
  'Core/Annotation' => ['AnnotationTool.swift', 'AnnotationManager.swift'],
  'Core/Layout' => ['MultiDeviceLayoutManager.swift'],
  'Core/Recording' => ['RecordingManager.swift'],
  'Core/Connection' => ['ConnectionManager.swift'],
  'Views/Performance' => ['PerformancePanel.swift'],
  'Views/Stage' => ['MultiDeviceContainerView.swift', 'DeviceFrameView.swift'],
  'Views/Annotation' => ['AnnotationCanvasView.swift', 'AnnotationToolbar.swift'],
  'Views/Recording' => ['RecordingControlView.swift'],
  'Views/Settings' => ['SettingsView.swift'],
  'Views/Components' => ['QuickSettingsPanel.swift']
}

# 查找或创建组
def find_or_create_group(project, path_components, parent_group)
  return parent_group if path_components.empty?
  
  current_name = path_components.first
  remaining = path_components[1..-1]
  
  group = parent_group.children.find { |child| child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.name == current_name }
  
  unless group
    group = parent_group.new_group(current_name, current_name)
    puts "Created group: #{current_name}"
  end
  
  find_or_create_group(project, remaining, group)
end

# 获取 DemoConsole 主组
main_group = project.main_group.children.find { |g| g.display_name == 'DemoConsole' }

unless main_group
  puts "Error: Cannot find DemoConsole group"
  exit 1
end

files_to_add.each do |relative_path, filenames|
  path_components = relative_path.split('/')
  group = find_or_create_group(project, path_components, main_group)
  
  filenames.each do |filename|
    file_path = "DemoConsole/#{relative_path}/#{filename}"
    
    # 检查文件是否已存在于项目中
    existing = group.files.find { |f| f.display_name == filename }
    
    if existing
      puts "Skip (exists): #{file_path}"
    elsif File.exist?(file_path)
      # 使用相对于组的路径
      file_ref = group.new_file(filename)
      target.source_build_phase.add_file_reference(file_ref)
      puts "Added: #{file_path}"
    else
      puts "Warning: File not found: #{file_path}"
    end
  end
end

project.save
puts "\nProject saved successfully!"
