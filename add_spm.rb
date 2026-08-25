require 'xcodeproj'

project_path = 'ZEWatch.xcodeproj'
project = Xcodeproj::Project.open(project_path)
companion_target = project.targets.find { |t| t.name == 'ZEWatchCompanion' }

url = "https://github.com/ggerganov/llama.cpp.git"

# 1. 检查是否已经加过 package reference
req = project.root_object.package_references.find { |pkg| pkg.repositoryURL == url }
unless req
  req = Xcodeproj::Project::Object::XCRemoteSwiftPackageReference.new(project, project.generate_uuid)
  req.repositoryURL = url
  req.requirement = {
    "kind" => "branch",
    "branch" => "master"
  }
  project.root_object.package_references << req
end

# 2. 创建产品依赖
product = companion_target.package_product_dependencies.find { |p| p.product_name == 'llama' }
unless product
  product = Xcodeproj::Project::Object::XCSwiftPackageProductDependency.new(project, project.generate_uuid)
  product.product_name = "llama"
  product.package = req
  companion_target.package_product_dependencies << product
end

# 3. 将其加到 Frameworks Build Phase 中 (使用 product_ref 而不是 file_ref)
build_file = companion_target.frameworks_build_phase.files.find { |bf| bf.product_ref == product }
unless build_file
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.product_ref = product
  companion_target.frameworks_build_phase.files << build_file
end

project.save
puts "Successfully added SPM dependency for llama.cpp!"
