require "spaceship"

key_id = ENV["ASC_KEY_ID"]
issuer_id = ENV["ASC_ISSUER_ID"]
key_path = ENV["ASC_KEY_PATH"]

puts "正在通过 App Store Connect API 建立连接..."
key = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: issuer_id,
  filepath: key_path
)
Spaceship::ConnectAPI.token = key

app = Spaceship::ConnectAPI::App.find("com.nevergone.zrxx.ios")
puts "已定位应用: #{app.name} (#{app.id})"

target_build_version = "20261105091148"
target_app_version = "1.0.3"

puts "目标版本: #{target_app_version}, 目标构建号: #{target_build_version}"

# 1. 寻找版本 1.0.3
v_103 = app.get_app_store_versions(filter: { versionString: target_app_version }).first
unless v_103
  puts "未找到 #{target_app_version}，正在创建..."
  v_103 = Spaceship::ConnectAPI.post_app_store_version(app_id: app.id, attributes: { versionString: target_app_version, platform: "IOS" })
end
puts "App Store 版本状态: #{v_103.app_store_state}"

# 2. 轮询等待 build 状态变为 VALID
max_attempts = 30
valid_build = nil

(1..max_attempts).each do |attempt|
  puts "[#{attempt}/#{max_attempts}] 正在查询 Apple 云端构建处理状态..."
  builds = app.get_builds(limit: 10, sort: "-uploadedDate", includes: "preReleaseVersion")
  
  matching_build = builds.find { |b| b.version == target_build_version }
  if matching_build
    puts " -> 找到构建包 #{matching_build.version}, 处理状态: #{matching_build.processing_state}"
    if matching_build.processing_state == "VALID"
      valid_build = matching_build
      break
    end
  else
    puts " -> Apple 队列入库中，稍候刷新..."
  end
  
  sleep 20
end

unless valid_build
  puts "构建包在等待时间内未就绪，请稍后再次检查。"
  exit 1
end

puts "=========================================================="
puts "构建包 #{valid_build.version} 已处于 VALID 状态！正在关联至 #{target_app_version}..."

# 3. 将构建包关联到 App Store 版本
begin
  v_103.select_build(build_id: valid_build.id)
  puts "成功挂载构建包 #{valid_build.version} 到版本 #{target_app_version}！"
rescue => e
  puts "select_build 提醒: #{e.message}"
end

# 4. 创建 Review Submission 并提交审核
puts "正在提交 App Store 审核..."
begin
  # 查找或创建 review submission
  submission = app.get_review_submissions(filter: { state: "READY_FOR_REVIEW" }).first
  submission ||= app.get_review_submissions(filter: { state: "WAITING_FOR_REVIEW" }).first
  
  if submission
    puts "已有审核申请 (ID: #{submission.id}, State: #{submission.state})"
  else
    puts "创建新的审核申请..."
    submission = app.create_review_submission(platform: "IOS")
  end

  # 添加版本到提审项
  begin
    submission.add_app_store_version_to_review_items(app_store_version_id: v_103.id)
    puts "已添加 1.0.3 版本至提审项。"
  rescue => e
    puts "添加提审项提示: #{e.message}"
  end

  # 正式提交
  puts "向 Apple 发送正式提交审核请求..."
  submission.submit_for_review
  puts "🎉 恭喜！版本 #{target_app_version} (Build #{valid_build.version}) 已成功正式提交给 App Store 审核！"
rescue => e
  puts "提交审核过程提示: #{e.message}"
  # 尝试通过 fastlane deliver 直接提审
  puts "尝试使用 Fastlane Deliver 自动最终提审..."
  cmd = "bundle exec fastlane submit_review build_number:#{target_build_version} app_version:#{target_app_version} skip_screenshots:true skip_metadata:true"
  system(cmd)
end
