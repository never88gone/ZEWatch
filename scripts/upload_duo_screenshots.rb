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
puts "已定位应用: #{app.name} (#{app.id})"

version = app.get_app_store_versions(filter: { versionString: "1.0.3" }).first
puts "定位版本: #{version.version_string} (ID: #{version.id}, 状态: #{version.app_store_state})"

loc = version.get_app_store_version_localizations.first
puts "定位本地化语言: #{loc.locale} (ID: #{loc.id})"

set = loc.get_app_screenshot_sets(includes: "appScreenshots").find { |s| s.screenshot_display_type == "APP_IPHONE_DUO" }
unless set
  puts "未找到 APP_IPHONE_DUO 截图集，正在创建..."
  set = loc.create_app_screenshot_set(attributes: { screenshotDisplayType: "APP_IPHONE_DUO" })
end
puts "APP_IPHONE_DUO 截图集 ID: #{set.id}"

# 清理已有截图
existing = set.app_screenshots || []
if existing.any?
  puts "正在清理已有旧截图 (#{existing.size} 张)..."
  existing.each do |sc|
    print "  - 删除 #{sc.file_name || sc.id}... "
    sc.delete!
    puts "完成"
  end
end

dir = "AppStore_Screenshots/Promotional_Pages/iPhone_Duo"
files = [
  "1_宣传页_修仙表盘工坊.png",
  "2_宣传页_洞府大盘.png",
  "3_宣传页_识海伴修.png",
  "4_宣传页_天降机缘.png",
  "5_宣传页_法器宝阁.png",
  "6_宣传页_健康五行法则.png"
]

puts "=========================================================="
puts "开始上传 6 张 iPhone Duo 专属宣传海报 (1398 x 2034)..."
puts "=========================================================="

uploaded_ids = []
files.each_with_index do |filename, index|
  filepath = File.join(dir, filename)
  unless File.exist?(filepath)
    puts "❌ 错误: 未找到文件 #{filepath}"
    next
  end

  puts "[#{index + 1}/#{files.size}] 正在上传 #{filename}..."
  screenshot = set.upload_screenshot(path: filepath)
  puts "  -> 成功创建上传任务: #{screenshot.id}"
  uploaded_ids << screenshot.id
end

puts "=========================================================="
puts "所有文件已推送至 Apple 服务器，正在轮询云端处理状态..."
puts "=========================================================="

max_wait = 20
(1..max_wait).each do |attempt|
  sleep 6
  set_refreshed = loc.get_app_screenshot_sets(includes: "appScreenshots").find { |s| s.id == set.id }
  screenshots = set_refreshed.app_screenshots || []
  
  states = screenshots.map { |sc| sc.asset_delivery_state ? sc.asset_delivery_state["state"] : "PROCESSING" }
  complete_count = states.count("COMPLETE")
  failed_count = states.count("FAILED")
  
  puts "[#{attempt}/#{max_wait}] 已处理就绪: #{complete_count}/#{files.size} (失败: #{failed_count})"
  
  if complete_count == files.size
    puts "🎉 全部 6 张 iPhone Duo 截图已 100% 处理成功 (COMPLETE)！"
    break
  end
  
  if failed_count > 0
    puts "⚠️ 警告: 部分截图处理失败，详情如下:"
    screenshots.each do |sc|
      if sc.asset_delivery_state && sc.asset_delivery_state["state"] == "FAILED"
        puts "  - #{sc.file_name}: #{sc.asset_delivery_state['errors']}"
      end
    end
    break
  end
end

puts "=========================================================="
puts "iPhone Duo 截图上传任务执行完毕！"
puts "=========================================================="
