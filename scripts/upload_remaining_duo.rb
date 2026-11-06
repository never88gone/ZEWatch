require "spaceship"

key_id = "FK497QS295"
issuer_id = "eea5ec99-6a0a-44be-a598-5c2fd016b10c"
key_path = "/Volumes/MacintoshData/Work/MY/Project/publicinfo/apple/AuthKey_FK497QS295.p8"

puts "=========================================================="
puts "正在建立 App Store Connect API 连接..."
puts "=========================================================="

token = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: issuer_id,
  filepath: key_path
)
Spaceship::ConnectAPI.token = token

app = Spaceship::ConnectAPI::App.find("com.nevergone.zrxx.ios")
version = app.get_app_store_versions(filter: { versionString: "1.0.3" }).first
loc = version.get_app_store_version_localizations.first

set = loc.get_app_screenshot_sets(includes: "appScreenshots").find { |s| s.screenshot_display_type == "APP_IPHONE_DUO" }

existing_names = (set.app_screenshots || []).map(&:file_name)
puts "已存在截图: #{existing_names.join(', ')}"

dir = "AppStore_Screenshots/Promotional_Pages/iPhone_Duo"
files = [
  "1_宣传页_修仙表盘工坊.png",
  "2_宣传页_洞府大盘.png",
  "3_宣传页_识海伴修.png",
  "4_宣传页_天降机缘.png",
  "5_宣传页_法器宝阁.png",
  "6_宣传页_健康五行法则.png"
]

remaining_files = files.reject { |f| existing_names.include?(f) }
puts "待上传文件: #{remaining_files.join(', ')}"

remaining_files.each_with_index do |filename, idx|
  filepath = File.join(dir, filename)
  puts "[#{idx + 1}/#{remaining_files.size}] 正在并发投递 #{filename} (wait_for_processing: false)..."
  # 关键：wait_for_processing: false，不阻塞等待转码，上传完分片立刻进入下一个
  screenshot = set.upload_screenshot(path: filepath, wait_for_processing: false)
  puts "  -> 投递成功: #{screenshot.id}"
end

puts "=========================================================="
puts "全部截图分片已成功上传！正在监控云端转码状态..."
puts "=========================================================="

15.times do |attempt|
  sleep 8
  set_refreshed = loc.get_app_screenshot_sets(includes: "appScreenshots").find { |s| s.id == set.id }
  current = set_refreshed.app_screenshots || []
  
  status_map = {}
  current.each do |sc|
    status_map[sc.file_name] = sc.asset_delivery_state ? sc.asset_delivery_state["state"] : "PROCESSING"
  end
  
  complete_count = status_map.values.count("COMPLETE")
  upload_count = status_map.values.count("UPLOAD_COMPLETE")
  
  puts "[#{attempt + 1}/15] 状态统计: 就绪 #{complete_count}/6 | 云端处理中 #{upload_count}/6"
  status_map.each { |name, st| puts "  - #{name}: #{st}" }
  
  if complete_count == 6
    puts "🎉 恭喜！iPhone Duo 全部 6 张宣传截图已 100% 成功处理完毕！"
    break
  end
end
