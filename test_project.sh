#!/bin/bash

# FlowKey 项目测试脚本
# 用于测试项目的核心功能和依赖项

echo "=== FlowKey 项目测试报告 ==="
echo "测试时间: $(date)"
echo "测试平台: $(uname -a)"
echo ""

# 检查 Swift 版本
echo "1. 检查 Swift 版本..."
swift --version
echo ""

# 检查项目结构
echo "2. 检查项目结构..."
if [ -f "Package.swift" ]; then
    echo "✅ Package.swift 存在"
else
    echo "❌ Package.swift 不存在"
fi

if [ -d "Sources" ]; then
    echo "✅ Sources 目录存在"
else
    echo "❌ Sources 目录不存在"
fi

if [ -d "Sources/FlowKeyTests" ]; then
    echo "✅ 测试目录存在"
else
    echo "❌ 测试目录不存在"
fi
echo ""

# 检查依赖项
echo "3. 检查依赖项..."
echo "Package.swift 中的依赖项:"
grep -A 10 "dependencies:" Package.swift
echo ""

# 检查源代码文件
echo "4. 检查源代码文件..."
find Sources/FlowKey -name "*.swift" | wc -l | xargs echo "Swift 文件总数:"
echo ""

# 检查测试文件
echo "5. 检查测试文件..."
find Sources/FlowKeyTests -name "*.swift" | wc -l | xargs echo "测试文件总数:"
echo ""

# 尝试解析包
echo "6. 尝试解析包..."
swift package describe 2>/dev/null || echo "❌ 包解析失败"
echo ""

# 检查是否有编译错误
echo "7. 检查编译错误..."
echo "尝试编译主要源文件..."
swift -frontend -parse Sources/FlowKey/App/FlowKeyApp.swift 2>&1 | head -10
echo ""

# 检查测试是否可以编译
echo "8. 检查测试编译..."
swift -frontend -parse Sources/FlowKeyTests/UnitTests/TranslationTests.swift 2>&1 | head -10
echo ""

# 生成建议
echo "9. 测试建议..."
echo "基于当前测试结果，建议："
echo "- 检查 Swift 版本兼容性"
echo "- 修复编译错误"
echo "- 确保所有依赖项正确安装"
echo "- 更新测试文件以匹配当前 API"
echo ""

echo "=== 测试完成 ==="