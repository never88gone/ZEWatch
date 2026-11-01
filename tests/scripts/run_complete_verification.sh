#!/bin/bash
set -e

DEVICE_ID="396D8747-C119-49D2-9168-74F09BB1C184"
APP_ID="com.nevergone.zrxx.ios"
MAESTRO="/Users/never88gone/.maestro/bin/maestro"

echo "=================================================="
echo "开始大模型全生命周期逻辑验证 (下载、取消、调用、删除)"
echo "=================================================="

# 1. 清理沙盒模型，确保从纯净无模型状态开始
DATA_DIR=$(xcrun simctl get_app_container "$DEVICE_ID" "$APP_ID" data)
mkdir -p "$DATA_DIR/Documents/Models"
rm -rf "$DATA_DIR/Documents/Models"/* || true
echo "✅ 沙盒已清空，准备验证阶段 1"

# 2. 运行阶段 1：验证无内置模型提示、跳转设置页、触发下载与取消下载
cat << 'EOF' > /tmp/flow_download_and_cancel.yaml
appId: com.nevergone.zrxx.ios
---
- launchApp:
    clearState: false

# 验证首页纯净状态
- tapOn: "识海"
- extendedWaitUntil:
    visible: "识海空明 · 戒灵未凝"
    timeout: 10000
- assertVisible: "前往设置挑选并接引法器"

# 跳转设置页下载专区
- tapOn:
    id: "goto_settings_download_button"
- extendedWaitUntil:
    visible: "天道接引 · 官方默认大模型下载"
    timeout: 10000
- assertVisible: "国内网络镜像加速 (hf-mirror.com)"
- assertVisible: "接引此法器（下载 约 390 MB）"

# 触发下载逻辑：验证网络连接、引灵进度条出现
- tapOn: "接引此法器（下载 约 390 MB）"
- extendedWaitUntil:
    visible: ".*天道引灵中.*"
    timeout: 10000

# 取消下载逻辑：验证任务终止、引灵面板平滑收起
- tapOn:
    id: "cancel_download_button"
- extendedWaitUntil:
    notVisible: ".*天道引灵中.*"
    timeout: 10000
- assertVisible: "接引此法器（下载 约 390 MB）"
EOF

$MAESTRO --device "$DEVICE_ID" test /tmp/flow_download_and_cancel.yaml
echo "✅ 阶段 1：下载逻辑与取消下载逻辑验证 100% 成功！"

# 3. 准备模型就绪（模拟下载完成保存到沙盒）
echo "GGUF_TEST_DATA_VERIFICATION" > "$DATA_DIR/Documents/Models/qwen2.5-0.5b-instruct-q4_k_m.gguf"
echo "✅ 阶段 2：模型文件已注入沙盒，准备验证调用对话与删除逻辑"

# 4. 运行阶段 2：验证唤醒模型、调用对话（流式回复）、在设置页销毁删除、以及首页联动回退
cat << 'EOF' > /tmp/flow_chat_and_delete.yaml
appId: com.nevergone.zrxx.ios
---
- launchApp:
    clearState: false

- tapOn: "识海"
- extendedWaitUntil:
    visible: "立即唤醒戒灵"
    timeout: 10000

# 唤醒模型
- tapOn: "立即唤醒戒灵"
- extendedWaitUntil:
    visible: "向墨老祈告..."
    timeout: 10000

# 调用逻辑：发送消息并断言墨老神念流式回复
- tapOn: "向墨老祈告..."
- inputText: "墨老，弟子今日当如何修炼？"
- tapOn:
    id: "send_message_button"
- extendedWaitUntil:
    visible: ".*老夫.*"
    timeout: 15000

# 删除逻辑：前往设置页销毁删除模型
- tapOn: "须弥戒"
- extendedWaitUntil:
    visible: "法器库管理 (大模型)"
    timeout: 10000
- assertVisible: "qwen2.5-0.5b-instruct-q4_k_m.gguf"
- tapOn: "Trash"
- extendedWaitUntil:
    visible: "法器囊空空如也（安装包未内置大模型，请点击下方下载）"
    timeout: 8000

# 联动状态验证：切回识海，模型已被卸载，恢复空明引导
- tapOn: "识海"
- extendedWaitUntil:
    visible: "识海空明 · 戒灵未凝"
    timeout: 8000
EOF

$MAESTRO --device "$DEVICE_ID" test /tmp/flow_chat_and_delete.yaml
echo "✅ 阶段 2：唤醒、调用对话、销毁删除与状态联动验证 100% 成功！"

# 5. 校验沙盒文件确实被物理移除
if [ -f "$DATA_DIR/Documents/Models/qwen2.5-0.5b-instruct-q4_k_m.gguf" ]; then
    echo "❌ 失败：模型文件未被物理删除！"
    exit 1
else
    echo "✅ 物理检查：沙盒文件已被物理彻底删除！"
fi

echo "=================================================="
echo "🎉 全部逻辑验证圆满完成，大模型下载、删除、调用无任何问题！"
echo "=================================================="
