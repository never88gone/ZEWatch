# GitHub Actions TestFlight 自动化构建 Secrets 配置指南

本项目已配置 GitHub Actions 工作流（[`.github/workflows/testflight.yml`](.github/workflows/testflight.yml)），当您向 `main` 分支推送代码或在 GitHub 页面上手动触发时，GitHub 将自动完成证书安装、构建归档并上传至 TestFlight。

---

## 一、需在 GitHub 配置的 Secrets 清单

请前往 GitHub 仓库页面：**Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**，依次添加以下 7 个 Secret：

| Secret 名称 | 必须 | 说明 | 获取方式 / 命令 |
| :--- | :---: | :--- | :--- |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | ✅ | API Key ID | `FK497QS295` |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | ✅ | API Key Issuer ID (UUID) | `eea5ec99-6a0a-44be-a598-5c2fd016b10c` |
| `APP_STORE_CONNECT_API_KEY_KEY` | ✅ | API Key 私钥内容（Base64 或 PEM 原文） | 见下方一键复制命令 |
| `P12_BASE64` | ✅ | Apple Distribution 证书及私钥 (.p12) 的 Base64 编码 | 见下方证书导出与复制步骤 |
| `P12_PASSWORD` | ✅ | 导出 .p12 证书时设置的密码 | 您导出证书时自定义的密码 |
| `PROVISION_PROFILE_IOS_BASE64` | ✅ | iOS App 描述文件的 Base64 编码 | 见下方一键复制命令 |
| `PROVISION_PROFILE_WATCH_BASE64` | ✅ | watchOS App 描述文件的 Base64 编码 | 见下方一键复制命令 |

---

## 二、本地一键获取各 Secret 值的命令

在您本机的终端运行以下命令，即可直接将各个 Secret 的内容拷贝到剪贴板：

### 1. 复制 `APP_STORE_CONNECT_API_KEY_KEY`
```bash
# 直接将 Base64 格式的 API Key 私钥复制到系统剪贴板：
echo "LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEJIa3dkd0lCQVFRZ0RpUE9oREd2NnNhQllFakgKTmx4bEF0L1JqQllQS0RHZFFtbVkzV0tKQlk2Z0NnWUlLb1pJemowREFRZWhSQU5DQUFTUTU1WHkzWjRsR0N0RApTRzFzVjdNa0RKbjdlbkVOeGZXb0F5Z2xHMXpWZ2Jabnd4d0hyN3dZQnRmUGdBZ2NyY2ptQWxWTjBYdFpMQm9XClQ2UTdFdjY1Ci0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0=" | pbcopy
```

### 2. 复制 `PROVISION_PROFILE_IOS_BASE64` (iOS 描述文件)
```bash
base64 -i "$HOME/Library/MobileDevice/Provisioning Profiles/c91171c3-0cf8-4a27-a56d-fffabb9335ca.mobileprovision" | pbcopy
```

### 3. 复制 `PROVISION_PROFILE_WATCH_BASE64` (Watch 描述文件)
```bash
base64 -i "$HOME/Library/MobileDevice/Provisioning Profiles/979174ac-a4d2-41a2-8ae6-184495b67086.mobileprovision" | pbcopy
```

### 4. 导出并复制 `P12_BASE64` 与 `P12_PASSWORD`
由于 Distribution 证书私钥受到 macOS 系统安全保护，请按以下简易步骤导出：
1. 打开 macOS 的 **“钥匙串访问” (Keychain Access)**；
2. 在左侧选择 **“登录 (login)”** -> **“我的证书 (My Certificates)”**；
3. 找到名为 **`Apple Distribution: zhao xiangfeng (876385K952)`** 的证书；
4. 右键点击它，选择 **“导出 Apple Distribution...”**；
5. 文件格式选择 **个人信息交换 (.p12)**，保存至桌面（例如 `dist.p12`）；
6. 在弹窗中输入一个用于保护该文件的密码（此密码即填入 GitHub Secret `P12_PASSWORD`），随后输入 Mac 登录密码确认导出；
7. 在终端运行以下命令将导出的 .p12 转为 Base64 并复制到剪贴板：
   ```bash
   base64 -i ~/Desktop/dist.p12 | pbcopy
   ```
8. 粘贴至 GitHub Secret `P12_BASE64`；完成后建议删除桌面的 `dist.p12`：
   ```bash
   rm -f ~/Desktop/dist.p12
   ```

---

## 三、触发与验证

完成上述 Secrets 配置后：
1. **自动构建**：只要向 GitHub `main` 分支执行 `git push`，工作流便会自动启动；
2. **手动触发**：亦可前往 GitHub 仓库的 **Actions** 标签页，点击 **“Build & Upload to TestFlight”** -> **“Run workflow”** 手动触发构建与上传。
