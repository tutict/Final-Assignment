#!/bin/bash
set -e

echo "=== 1/6 Flutter 版本 ==="
flutter --version
dart --version

echo "=== 2/6 获取依赖 ==="
flutter pub get

echo "=== 3/6 静态分析 ==="
flutter analyze
echo "分析通过"

echo "=== 4/6 重新生成代码 ==="
dart run build_runner build --delete-conflicting-outputs
echo "代码生成完成"

echo "=== 5/6 运行测试 ==="
flutter test
echo "测试通过"

echo "=== 6/6 构建验证 ==="
flutter build apk --debug --no-pub
echo "构建通过"

echo ""
echo "Flutter 升级验证完成"
