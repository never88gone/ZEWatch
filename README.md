# 糖葫芦修仙 

<p align="left">
  <img src="https://img.shields.io/badge/Platform-iOS%20|%20watchOS-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Status-Open%20Source-green" alt="Status">
  <a href="https://testflight.apple.com/join/CUuHpJ4J">
    <img src="https://img.shields.io/badge/TestFlight-Join%20Beta-00C7B7?logo=apple&logoColor=white" alt="TestFlight">
  </a>
</p>

**糖葫芦修仙** 是一款将运动健康数据与东方玄幻修真深度融合的“中二”锻炼应用。应用通过将 Apple Watch 获取到的现实运动与健康数据进行转化，让你的每一次行走、每一分锻炼，都化作虚拟修仙宇宙中澎湃的“真气”。本项目代码已开源，欢迎各位道友一同参悟源码。

## 🌟 核心特色

项目包含 iOS 客户端及 watchOS 穿戴端双版本，分别承载了修仙的不同乐趣体验：

### 📱 iOS 端：你的随身“戒指老爷爷”
- **AI 伴修系统**：iOS 端底层集成了本地运行的大语言模型（LLM），化身为暂居你戒指中的上古残魂“墨老”。
- **沉浸式互动对话**：墨老性格清高毒舌又护短，他能感知到你从 Apple Watch 端同步过来的修行状态（境界、修为等）。每日你可以与他互动，他会依据你的现实状态给出极具玄幻风味、“恨铁不成钢”的反馈。
- **天降机缘**：当你在现实中坚持锻炼，向道之心坚守时，老爷爷也许会在对话指点中大发慈悲，动态触发“机缘事件”，直接赐予你一笔不菲的修为。

### ⌚️ watchOS 端：渡劫与日常修行的大千世界
手表端是修仙的交互核心，利用硬件传感器特征与健康数据记录，带来沉浸式腕上修真：
- **健康即真气**：深度集成 HealthKit，将现实生活中的卡路里消耗、步数等健康数据，自动化转化为升级所需的五行“真气”。
- **灵牌与洞府管理**：随时在手腕上查看个人灵根资质、境界（炼气、筑基、金丹等...）以及五行聚灵阵的效率。
- **乾坤丹炉（炼丹系统）**：创新交互体验！使用 Apple Watch 的 **数码表冠（Digital Crown）** 操控炼丹火候并提取精粹，成丹后可借此突破瓶颈。
- **宗门试炼**：定时发布各类运动试炼任务，指导你在现实中完成特定的体能锻炼以换取法宝与功法。
- **渡劫挑战模式**：每次突破大境界时将引来天雷。你需要紧握数码表冠，在腕间迅速操作阵眼游标，抵抗劫雷游移。若心脉失守，则抱憾出关。
- **游历与藏经阁**：云游四海，获取上古功法，构建属于自己的修炼流派。

## 🚀 快速开始

### 环境依赖
- **IDE**: Xcode 15 及以上版本
- **OS**: iOS 16.0+, watchOS 10.0+

### 本地运行
1. 克隆本仓库到本地。
2. **下载 AI 模型（必做项）**：由于大型 LLM 模型文件受体积限制已被 `.gitignore` 忽略，您需要在本地准备好大语言模型的量化文件（`.gguf` 格式）。
   > **Note**: 前期项目曾集成过 `Qwen3.5-0.8B`，但由于其逻辑与角色扮演能力较弱，后续项目将全面测试并推荐采用 **Gemma 2B** 或其他参数量适中、指令跟随更好的大模型。
   > 请自行前往 HuggingFace 寻找对应的 `GGUF` 权重文件，并将其放置于 `ZEWatchCompanion/Models/` 目录下，并确保该文件添加进了 Xcode 的 `Copy Bundle Resources` 流程中。
3. 双击打开 `ZEWatch.xcodeproj` 工程文件。
4. 进入 `Signing & Capabilities` 选项卡，替换配置为您自己的 Apple Developer Team。
5. 本项目深度依赖健康运动数据，请务必保证 HealthKit 权项已配置开启。
6. 选择对应的设备模拟器或真机，运行 `ZEWatchApp` (watchOS) 和 `ZEWatchCompanion` (iOS) Target。

## 🤝 参与贡献
本项目现已全面开源。无论你是对 AI 本地推理集成（`llama.cpp`）、watchOS 独占硬件交互开发（如数码表冠、触觉反馈），还是对极其“中二”的修真游戏玩法设计有独特想法，都欢迎提交 Pull Request 或者建立 Issue 探讨！

## 📞 技术支持与联系

如果您在使用中遇到任何问题，请参阅我们的 [用户支持页面 (SUPPORT.md)](SUPPORT.md)，其中包含：

- **常见问题 (FAQ)**: 应用功能、HealthKit 授权、数据安全等常见疑问解答
- **隐私政策**: 查阅 [PrivacyPolicy.md](PrivacyPolicy.md) 了解我们对数据安全的承诺
- **项目 GitHub**: [GitHub 仓库](https://github.com/never88gone/ZEWatch)
- **Telegram 频道**: [糖葫芦 TVOS](https://t.me/tanghulutvos)
- **联系邮箱**: hsb@myit2017.cn
- **官方网站**: [www.myit2017.cn](https://www.myit2017.cn)

---
*"灵气枯竭的末法时代，唯有自律，方可证道长生。"*

