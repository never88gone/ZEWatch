require 'xcodeproj'

project_path = 'ZEWatch.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# 1. 移除叫 llama.cpp 的 group
llama_group = project.main_group.find_subpath('llama.cpp', false)
if llama_group
  llama_group.clear()
  llama_group.remove_from_project()
  puts "Removed llama.cpp group"
end

# 移除 gguf 文件引用
project.files.each do |file|
  if file.path && file.path.end_with?('.gguf')
    file.remove_from_project()
    puts "Removed gguf file reference: #{file.path}"
  elsif file.path && file.path.include?('llama.cpp')
    file.remove_from_project()
    puts "Removed llama.cpp file reference: #{file.path}"
  end
end

# 清理僵尸 Build Files
project.targets.each do |target|
  target.build_phases.each do |phase|
    phase.files.each do |build_file|
      if build_file.file_ref.nil?
        build_file.remove_from_project()
      end
    end
  end
end

# 2. 添加 Swift Wrappers
wrapper_group = project.main_group.find_subpath('ZEWatchCompanion/LlamaWrapper', false)
if wrapper_group.nil?
  wrapper_group = project.main_group.new_group('LlamaWrapper', 'ZEWatchCompanion/LlamaWrapper')
end

companion_target = project.targets.find { |t| t.name == 'ZEWatchCompanion' }

['LlamaState.swift', 'LibLlama.swift'].each do |file_name|
  file_path = "ZEWatchCompanion/LlamaWrapper/#{file_name}"
  if File.exist?(file_path)
    file_ref = wrapper_group.files.find { |f| f.path == file_name }
    unless file_ref
      file_ref = wrapper_group.new_file(file_name)
    end
    if companion_target && !companion_target.source_build_phase.files_references.include?(file_ref)
      companion_target.source_build_phase.add_file_reference(file_ref, true)
    end
    puts "Added wrapper file: #{file_name}"
  end
end

project.save
puts "Project updated successfully!"
