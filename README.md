# FlowKey 智能输入法

一个运行在 Mac 上的智能输入法应用程序，集成本地 AI 服务，提供划词翻译、智能改写、语音记录等功能。

## 功能特性

### 核心功能
- ✅ **划词翻译**: 选中任何文本即可翻译
- ✅ **快捷翻译**: 三击空格键快速翻译当前输入
- ✅ **本地优先**: 支持本地翻译模型，保护隐私
- ✅ **多语言支持**: 支持中英日韩法德俄等多种语言

### AI 功能
- 🚧 **本地翻译模型**: 基于 MLX 的离线翻译
- 🚧 **语音识别**: 集成 Whisper 语音识别
- 🚧 **智能改写**: AI 文本优化和改写
- 🚧 **知识库**: 个人文档语义搜索

### 用户体验
- ✅ **简洁界面**: 优雅的 SwiftUI 界面
- ✅ **系统级集成**: 深度集成 macOS 系统
- ✅ **iCloud 同步**: 跨设备数据同步
- ✅ **隐私保护**: 本地数据处理

## 技术架构

### 核心技术栈
- **Swift + SwiftUI**: 原生 macOS 应用开发
- **MLX Swift**: 本地 AI 推理，Apple Silicon 优化
- **IMKInputMethod**: macOS 官方输入法框架
- **Composable Architecture**: 状态管理
- **Core Data**: 本地数据存储

### 项目结构
```
FlowKey/
├── FlowKey/                    # 主应用
│   ├── InputMethod/           # 输入法核心
│   ├── Models/                # 数据模型
│   ├── Services/              # 服务层
│   ├── Views/                 # UI 界面
│   └── App/                   # 应用入口
├── FlowKeyTests/              # 测试
├── FlowKeyInputMethod/        # 输入法扩展
└── Documentation/             # 文档
```

## 快速开始

### 环境要求
- macOS 13.0 或更高版本
- Xcode 14.0 或更高版本
- Swift 5.9 或更高版本

### 构建项目

1. 克隆项目：
```bash
git clone <repository-url>
cd flow-key
```

2. 构建应用：
```bash
./build.sh
```

3. 安装应用：
```bash
# 复制到应用程序文件夹
cp -r build/FlowKey.app /Applications/

# 复制输入法
mkdir -p ~/Library/Input\ Methods/
cp -r build/FlowKeyInputMethod.bundle ~/Library/Input\ Methods/
```

4. 启用输入法：
   - 打开系统偏好设置 > 键盘 > 输入法
   - 点击 "+" 添加输入法
   - 选择 "FlowKey" 并启用

## 使用说明

### 基本翻译
1. 在任何应用中选中文本
2. 翻译结果会自动显示
3. 点击复制按钮保存译文

### 快捷翻译
- 三击空格键：翻译当前选中的文本
- Cmd+Shift+T：手动触发翻译

### 语音输入
- 在设置中启用语音功能
- 点击麦克风按钮开始录音
- 说话后自动识别并翻译

### 知识库
- 导入个人文档到知识库
- 使用语义搜索快速查找信息
- 支持多种文档格式

## 开发指南

### 项目结构说明

#### InputMethod/
- `FlowInputController.swift`: 输入法控制器，处理用户输入
- `FlowInputMethod.swift`: 输入法主类，系统注册
- `FlowCandidateView.swift`: 候选词视图

#### Models/
- `Translation/`: 翻译相关模型和服务
- `KnowledgeBase/`: 知识库管理
- `Speech/`: 语音识别和处理

#### Services/
- `AIService.swift`: AI 服务统一接口
- `MLXService.swift`: MLX 框架集成
- `StorageService.swift`: 数据存储服务
- `SyncService.swift`: iCloud 同步服务

#### Views/
- `Settings/`: 设置界面
- `Overlay/`: 悬浮窗界面

### 开发工作流程

1. **环境设置**
   ```bash
   # 安装依赖
   swift package update
   
   # 生成 Xcode 项目
   swift package generate-xcodeproj
   ```

2. **开发**
   ```bash
   # 运行开发服务器
   swift run
   
   # 运行测试
   swift test
   ```

3. **构建**
   ```bash
   # 构建发布版本
   swift build -c release
   ```

### 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 常见问题

### Q: 输入法无法启用？
A: 确保已将输入法复制到 `~/Library/Input Methods/` 并在系统设置中启用。

### Q: 翻译功能不工作？
A: 检查网络连接，或确保已下载本地翻译模型。

### Q: 语音识别失败？
A: 确保已授予麦克风权限，并检查语音模型是否已下载。

## 更新日志

### v1.0.0 (2025-08-23)
- ✅ 基础输入法框架
- ✅ 划词翻译功能
- ✅ 在线翻译 API 集成
- ✅ 基础 UI 界面
- ✅ 设置界面

### 计划功能
- 🚧 本地 AI 模型集成
- 🚧 语音识别功能
- 🚧 知识库系统
- 🚧 iCloud 同步
- 🚧 更多语言支持

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 联系我们

- 问题反馈：[GitHub Issues](https://github.com/zh30/flow-key/issues)
- 功能请求：[GitHub Discussions](https://github.com/zh30/flow-key/discussions)
- 邮箱：support@flowkey.app

---

**FlowKey** - 让输入更智能，让沟通更顺畅。