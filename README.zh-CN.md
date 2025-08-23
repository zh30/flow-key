[English](README.md) | [简体中文](README.zh-CN.md) | [Español](README.es.md) | [हिन्दी](README.hi.md) | [العربية](README.ar.md)

# FlowKey — 智能输入法 for macOS

一款尖端的 macOS 输入法应用程序，集成本地 AI 服务，提供实时翻译、语音识别和智能文本处理功能，支持 5 种主要语言。

## 🌍 多语言支持

FlowKey 支持全球使用最广泛的 5 种语言：

- 🇺🇸 **English** (默认)
- 🇨🇳 **中文** (Chinese)
- 🇪🇸 **Español** (Spanish)
- 🇮🇳 **हिन्दी** (Hindi)
- 🇸🇦 **العربية** (Arabic)

## ✨ 核心功能

### 核心翻译功能
- ✅ **划词翻译**: 即时翻译任何选中的文本
- ✅ **快速翻译**: 三击空格键立即翻译
- ✅ **本地优先**: 设备端 AI 模型确保完全隐私
- ✅ **5 种语言**: 在主要世界语言间无缝切换

### AI 能力
- 🚧 **离线翻译**: 基于 MLX 的本地 AI 推理
- 🚧 **语音识别**: 基于 Whisper 的语音输入
- 🚧 **智能重写**: AI 驱动的文本优化
- 🚧 **知识库**: 个人文档的语义搜索

### 用户体验
- ✅ **原生界面**: 简洁的 SwiftUI 界面，完全本地化
- ✅ **深度集成**: 原生 macOS 系统集成
- ✅ **实时切换**: 即时语言切换
- ✅ **隐私优先**: 所有处理都在您的设备上完成

## 🏗️ 架构

### 技术栈
- **Swift + SwiftUI**: 原生 macOS 开发
- **MLX Swift**: 为 Apple Silicon 优化的本地 AI 推理
- **IMKInputMethod**: 官方 macOS 输入法框架
- **Core Data**: 强大的本地数据持久化
- **iCloud 同步**: 跨设备无缝同步

### 项目结构
```
FlowKey/
├── Sources/FlowKey/
│   ├── App/                    # 应用程序入口点
│   ├── InputMethod/           # 输入法核心功能
│   ├── Models/                # 数据模型和服务
│   ├── Services/              # 业务逻辑层
│   ├── Views/                 # 用户界面
│   └── Resources/             # 资源和素材
├── Sources/FlowKeyTests/      # 测试套件
└── Documentation/             # 项目文档
```

## 🚀 快速开始

### 系统要求
- macOS 14.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本
- 推荐 Apple Silicon Mac 以获得最佳 AI 功能

### 快速启动

1. **克隆仓库**
```bash
git clone <repository-url>
cd flow-key
```

2. **构建应用程序**
```bash
# 开发构建
swift build

# 发布构建
swift build -c release
```

3. **运行应用程序**
```bash
# 开发模式
swift run

# 或使用构建脚本
./run_app.sh
```

### 安装

1. **复制到应用程序文件夹**
```bash
cp -r .build/debug/FlowKey.app /Applications/
```

2. **启用输入法**
   - 打开系统设置 > 键盘 > 输入法
   - 点击 "+" 添加新的输入源
   - 从列表中选择 "FlowKey"
   - 在您的输入源中启用它

## 🎯 使用指南

### 基础翻译
1. 在任何应用程序中选择文本
2. 翻译会自动出现在悬浮窗口中
3. 使用复制按钮保存结果

### 快捷操作
- **三击空格**: 立即翻译当前选中的文本
- **Cmd+Shift+T**: 手动触发翻译
- **Cmd+Shift+V**: 激活语音输入

### 语音功能
1. 在设置中启用语音识别
2. 点击麦克风按钮或使用语音快捷键
3. 自然说话 - 文本会被转录和翻译
4. 结果会立即显示并提供复制选项

### 语言切换
1. 打开 FlowKey 设置
2. 导航到"应用语言"部分
3. 从下拉菜单中选择您偏好的语言
4. 界面会立即更新，完全本地化

## 🔧 开发

### 开发环境设置
```bash
# 安装依赖
swift package update

# 生成 Xcode 项目
swift package generate-xcodeproj

# 运行测试
swift test

# 构建发布版本
swift build -c release
```

### 核心组件

#### 输入法核心
- `FlowInputController.swift`: 处理用户输入和文本处理
- `FlowInputMethod.swift`: 主要输入法类和系统注册
- `FlowCandidateView.swift`: 候选选择界面

#### AI 服务
- `MLXService.swift`: 本地 AI 模型集成
- `AIService.swift`: 统一 AI 服务接口
- `SpeechRecognizer.swift`: 语音识别功能

#### 本地化
- `LocalizationService.swift`: 多语言支持系统
- 支持 5 种主要语言，实时切换
- 完整的 UI 本地化和用户偏好持久化

### 构建分发版本
```bash
# 构建发布版本
swift build -c release

# 创建应用包
mkdir -p FlowKey.app/Contents/MacOS
cp .build/release/FlowKey FlowKey.app/Contents/MacOS/

# 签名应用（分发必需）
codesign --deep --force --verify --verbose --sign "-" FlowKey.app
```

## 🤝 贡献

我们欢迎贡献！请按照以下步骤：

1. **Fork 仓库**
2. **创建功能分支** (`git checkout -b feature/新功能`)
3. **提交更改** (`git commit -m '添加新功能'`)
4. **推送到分支** (`git push origin feature/新功能`)
5. **打开 Pull Request`

### 开发指南
- 遵循 Swift 编码规范
- 为新功能添加测试
- 更新文档
- 提交前确保所有测试通过

## ❓ 常见问题

### Q: 如何启用输入法？
A: 将应用复制到应用程序文件夹，然后转到系统设置 > 键盘 > 输入法，点击 "+" 并选择 "FlowKey"。

### Q: 翻译功能不工作？
A: 检查您的网络连接以进行在线翻译，或确保已下载本地 AI 模型以进行离线模式。

### Q: 语音识别不工作？
A: 在系统设置 > 隐私与安全性 > 麦克风中授予麦克风权限，并确保已下载语音模型。

### Q: 如何更改界面语言？
A: 打开 FlowKey 设置，转到"应用语言"，从下拉菜单中选择您偏好的语言。

## 📋 更新日志

### v1.0.0 (2025-08-23)
- ✅ 完整的多语言支持（5 种语言）
- ✅ 实时语言切换
- ✅ 本地 AI 模型集成框架
- ✅ 带悬浮界面的划词翻译
- ✅ 语音识别基础
- ✅ 隐私优先架构
- ✅ iCloud 同步功能

### 开发路线图
- 🚧 高级离线 AI 模型
- 🚧 增强语音识别
- 🚧 带语义搜索的知识库
- 🚧 智能文本重写
- 🚧 更多语言支持

## 📄 许可证

本项目基于 MIT 许可证。详情请参见 [LICENSE](LICENSE)。

## 📞 联系方式

- **问题反馈**: [GitHub Issues](https://github.com/zh30/flow-key/issues)
- **功能讨论**: [GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- **邮箱**: support@flowkey.app
- **网站**: [flowkey.app](https://flowkey.app)

---

**FlowKey** — 更智能地输入。更好地沟通。🚀

