# FlowKey 运行指南

## 最短路径

```bash
./script/build_and_run.sh
```

脚本会依次：

1. 结束旧的 FlowKey 进程。
2. 构建当前 Swift Package 可执行目标。
3. 在 `dist/FlowKey.app` 生成真实的 macOS app bundle。
4. 写入并校验最小 `Info.plist`。
5. 进行本地 ad-hoc 签名。
6. 通过 `open -n` 启动 app bundle。

不要直接运行 `.build/debug/FlowKey`。SwiftUI GUI 直接以命令行程序启动会缺少正确的 bundle metadata、Dock 激活和系统框架行为。

## 常用模式

```bash
./script/build_and_run.sh --verify     # 启动并确认进程存在
./script/build_and_run.sh --build-only # 只构建 app bundle
./script/build_and_run.sh --debug      # 使用 LLDB
./script/build_and_run.sh --logs       # 启动并查看统一日志
./script/test.sh                       # 运行测试
./build.sh                             # 构建 release app bundle
```

`./run_app.sh` 和 `./test_project.sh` 是兼容旧命令的薄封装，分别转发到新的统一脚本。

## 主窗口键盘操作

- `Command-1`：切换到翻译工作区。
- `Command-2`：切换到改写工作区。
- `Command-Return`：执行当前翻译或改写动作。
- 菜单栏“转换”（英文系统中为“Transform”）提供同样的模式、执行与清空命令，并跟随当前活动窗口。

源文本和结果之间使用可拖动的原生 macOS 分隔条；在“翻译 / 改写”间切换时，当前草稿会随用户继续流转。

## 首次翻译

Apple Translation 会提示下载源语言和目标语言。语言包由 macOS 管理，并可在系统设置中管理。取消下载后，FlowKey 会回到可操作状态并显示重试提示。

## 系统级快捷操作

1. 在其他 App 中选中文字。
2. 按 `Option-Space`（可在 FlowKey 设置中切换为其他组合键）。
3. 首次使用时，在“隐私与安全性 → 辅助功能”中允许 FlowKey。
4. 返回原 App，再次选中文字并按快捷键。
5. 选择“翻译、优化、缩短、正式化或校对”。完成后明确点击“复制”或“替换选区”。

FlowKey 不会为了取词模拟 `Command-C`，因此不会静默覆盖剪贴板。若当前 App 不支持 macOS 的选中文本接口、没有选区或处于安全输入框，浮动面板会解释原因；可改用“使用剪贴板”。授权状态变化后无需重新配置快捷键，回到源 App 再次触发即可。

改写使用 Apple 的设备端语言模型，需要 macOS 26、符合条件的 Mac、已启用 Apple Intelligence 且模型准备完成。如果任一条件不满足，FlowKey 会明确禁用改写，不会把文本转发到第三方服务器。

## 听写与术语

翻译和改写工作区的麦克风按钮只在点击后请求“语音识别”和“麦克风”权限。支持设备端识别时 FlowKey 会强制使用设备端识别，否则使用系统提供的普通 Apple Speech 路径，并在界面中如实显示状态。

“设置 → 术语”中的术语保存在本机 `~/Library/Application Support/FlowKey/terminology.json`。术语只进入设备端改写提示，不会被虚假宣称为 Apple Translation 的自定义词典。

## 界面语言

FlowKey 原生跟随 macOS 的首选语言，当前完整支持英语和简体中文，不提供重复的 App 内语言开关。开发时可用下面的命令只为本次进程强制中文，不会更改系统设置：

```bash
open -n dist/FlowKey.app --args -AppleLanguages '(zh-Hans)'
```

主 App 的菜单、工作区、设置、权限恢复提示及隐私用途说明都会同步切换；内嵌的 FlowKey Compose 也携带对应的简体中文资源。

## 可选的 FlowKey Compose 输入源

构建脚本会把独立的 `FlowKey Compose.app` 嵌入到：

```text
dist/FlowKey.app/Contents/Library/Input Methods/FlowKey Compose.app
```

它不会自动安装。需要时：

1. 打开 FlowKey 设置。
2. 在“Optional Input Method”中点击“Install Input Method…”。
3. 阅读确认信息后再点击“Install”。
4. 在 macOS 键盘设置的输入源中添加或选择 FlowKey Compose。

选中该输入源后，普通输入会原样交给当前 App。按 `Control-Option-F` 才进入 FlowKey 组合模式：输入内容会成为 marked text，候选窗口提供原文、大写、小写和标题格式；Return 提交，Escape 取消。设置页状态来自 macOS Text Input Sources API，不是应用内布尔值。

## 当前 Command Line Tools 说明

当前机器的 Swift 6.4 Command Line Tools 存在两处环境问题：

- 默认 `swiftbuild` 后端在初始化时报告 `Unknown error parsing property list`。
- macOS 27 SDK 引用了未随 Command Line Tools 安装的 `SwiftUIMacros` 插件。

项目脚本会在未安装完整 Xcode 时自动使用完整的 macOS 26.5 SDK 和 SwiftPM native 后端。测试脚本还会补齐 Swift Testing framework 的搜索路径。安装完整 Xcode 后，脚本会自动回到标准 SwiftPM 构建路径。
