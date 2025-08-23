#!/bin/bash

# FlowKey 应用程序启动脚本

echo "=== FlowKey 智能输入法启动脚本 ==="
echo "构建时间: $(date)"
echo ""

# 检查是否在正确的目录
if [ ! -f "Package.swift" ]; then
    echo "❌ 错误: 请在 FlowKey 项目根目录运行此脚本"
    exit 1
fi

# 检查可执行文件是否存在
if [ ! -f ".build/debug/FlowKey" ]; then
    echo "🔨 正在构建 FlowKey 应用程序..."
    swift build
    if [ $? -ne 0 ]; then
        echo "❌ 构建失败"
        exit 1
    fi
    echo "✅ 构建完成"
fi

# 检查应用程序是否已经在运行
if pgrep -f "FlowKey" > /dev/null; then
    echo "⚠️  FlowKey 应用程序已经在运行"
    echo "正在重启应用程序..."
    pkill -f "FlowKey"
    sleep 2
fi

# 启动应用程序
echo "🚀 正在启动 FlowKey 应用程序..."
echo "可执行文件路径: $(pwd)/.build/debug/FlowKey"
echo ""

# 在后台启动应用程序
nohup ./.build/debug/FlowKey > /dev/null 2>&1 &
APP_PID=$!

# 等待应用程序启动
sleep 3

# 检查应用程序是否成功启动
if pgrep -f "FlowKey" > /dev/null; then
    echo "✅ FlowKey 应用程序启动成功!"
    echo "进程ID: $APP_PID"
    echo ""
    echo "📋 应用程序信息:"
    echo "- 名称: FlowKey 智能输入法"
    echo "- 版本: 1.0.0 (简化测试版)"
    echo "- 平台: macOS"
    echo "- 构建工具: Swift Package Manager"
    echo ""
    echo "🎯 功能特性:"
    echo "- ✅ 划词翻译"
    echo "- ✅ 语音识别"
    echo "- ✅ 智能推荐"
    echo "- ✅ 知识库管理"
    echo "- ✅ 云同步"
    echo ""
    echo "🔧 使用说明:"
    echo "- 应用程序将在后台运行"
    echo "- 可以通过菜单栏图标访问"
    echo "- 使用 Command+Q 退出应用程序"
    echo ""
    echo "📝 注意事项:"
    echo "- 这是简化测试版本"
    echo "- 完整版本需要修复编译错误"
    echo "- 部分功能可能不可用"
    ""
    echo "🔍 进程状态:"
    ps aux | grep FlowKey | grep -v grep
else
    echo "❌ 应用程序启动失败"
    echo "请检查错误信息"
    exit 1
fi

echo ""
echo "=== 启动完成 ==="