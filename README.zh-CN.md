# FlowKey

[English](README.md)

FlowKey 是一个原生 macOS 文字工作台，围绕一个完整任务重新构建：用尽可能少的操作，把现有文字变成用户真正需要的文字。

## 当前真实可用

- 使用 Apple Translation 框架进行真实翻译。
- 自动检测源语言。
- 支持英语、简体中文、西班牙语、印地语和阿拉伯语目标语言。
- 原生语言下载、加载、成功、取消和错误状态。
- 左右双栏编辑，支持粘贴、复制、清空和交换语言。
- 可拖动的原生分栏，以及使用 Command-1/2 切换工作区的“Transform”菜单。
- Command-Return 在当前窗口执行当前转换动作。
- 原生“改写”工作区，提供优化、缩短、正式化和校对四种明确动作。
- 在 Mac 和系统模型支持时，通过 Apple Foundation Models 进行设备端私密改写；没有网络服务器退路。
- 仅在点击后启动 Apple Speech 听写，并完整处理麦克风、语音识别、语言不可用和错误状态。
- 小而专注的本地术语表，只作为设备端改写上下文。
- 可配置的全局“快捷操作”快捷键（默认 Option-Space）。
- 通过 macOS 辅助功能读取选中文本，并提供明确的授权与失败恢复状态。
- 紧凑的浮动面板可翻译或改写；复制和替换原选区都必须由用户明确点击。
- 无需辅助功能权限的剪贴板退路。
- 可选、独立构建并由用户明确安装的 InputMethodKit 系统输入源。
- `Control-Option-F` 启动的组合输入：marked text、原生候选、提交和取消完整可用；普通输入保持透传。
- 简洁的菜单栏入口和独立设置窗口。
- 界面原生跟随 macOS 系统语言，完整支持英语和简体中文，包括菜单、设置、权限恢复提示与内嵌输入法；不重复提供 App 内语言开关。
- 持久化默认目标语言、全局快捷键与主窗口自动复制设置。
- 35 个聚焦偏好、翻译与改写状态、快捷取词恢复、术语持久化、听写文本合并与组合输入的单元测试。

## 当前明确不宣称

当前 App 已内嵌真实的 InputMethodKit bundle，但不会在没有用户明确操作时安装或启用。生产签名、公证以及需要用户授权安装后的跨 App 输入源验收仍不作完成声明。这台开发 Mac 不符合 Apple 设备端语言模型资格，因此真实改写调用虽已实现并正确按可用性禁用，却无法在本机完成生成验收。听写权限、成功读取并替换其他 App 选区也仍需用户授权验收。通用个人知识库和 iCloud 同步被有意排除。旧原型代码仍保留在 `Sources/FlowKey`；当前目标只编译 `Sources/FlowKey/Rebuilt`、`Sources/FlowKeyInputMethod/Rebuilt` 和小型输入法核心。

第一性原理产品模型和分阶段路线图见 [plan.md](plan.md)。

## 环境要求

- macOS 15 或更高版本。
- 改写需要 macOS 26、符合条件的 Mac、已启用 Apple Intelligence 以及准备完成的设备端模型。
- 推荐安装完整 Xcode。
- 当前应用目标使用 Swift Package Manager。

仓库脚本也兼容当前 Swift 6.4 Command Line Tools 环境，自动规避其默认构建后端和最新 SwiftUI SDK 不完整的问题。

## 构建、测试、运行

```bash
# 构建、生成 dist/FlowKey.app 并启动
./script/build_and_run.sh

# 构建、启动并验证进程
./script/build_and_run.sh --verify

# 运行全部单元测试
./script/test.sh

# 生成优化后的 app bundle，但不启动
./build.sh
```

Codex 桌面的 Run 操作已经通过 `.codex/environments/environment.toml` 指向同一个构建启动脚本。

## 目录结构

```text
Sources/FlowKey/Rebuilt/
├── App/        # SwiftUI scene 与应用生命周期
├── Models/     # 偏好设置、语言选项、工作区状态
├── Services/   # 小而明确的 macOS 系统边界
└── Views/      # 翻译、菜单栏与设置界面

Sources/FlowKeyTests/UnitTests/  # Swift Testing 测试
Sources/FlowKeyInputMethod/      # 独立 IMKServer 可执行目标
Sources/FlowKeyInputMethodCore/  # 可测试的组合输入状态与候选
script/                         # 稳定的本地构建、运行和测试入口
```

## 隐私

FlowKey 使用 Apple Translation、Foundation Models 与 Speech 框架，不增加自己的语言服务器。只有在用户触发“快捷操作”时才检查辅助功能权限：它用于读取当前选区，并且只有用户再次明确点击后才会替换同一个选区。读取选区不会改写剪贴板；听写只在点击后启动。偏好保存在 `UserDefaults`，术语以本地 JSON 保存在 FlowKey 的 Application Support 目录。
