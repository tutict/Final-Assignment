# Flutter Frontend

`final_assignment_front` 是当前主线前端，使用 Flutter Web 承载驾驶员端、普通管理员端和超级管理员端的页面联调。

## 当前能力

- 登录、注册、验证码刷新和本地会话保持
- 驾驶员端个人工作台
- 驾驶员个人资料、违法详情、罚款缴纳、用户申诉、车辆登记、进度消息、地图入口
- 普通管理员工作台和六大业务页面
- 超级管理员日志审查与 RAG 资料管理入口
- 顶栏 AI 助手
- 统一暗色/亮色主题
- 可折叠侧边栏
- 小屏适配和业务错误展示组件

## 运行

推荐从仓库根目录使用脚本：

```bat
scripts\start-all.bat
```

只运行 Flutter Web：

```powershell
cd final_assignment_front
$env:DART_SUPPRESS_ANALYTICS='true'
C:\Users\tutic\Flutter\flutter\bin\flutter.bat run -d web-server --web-hostname 127.0.0.1 --web-port 3000
```

浏览器访问：

```text
http://127.0.0.1:3000
```

## 静态检查

```powershell
cd final_assignment_front
$env:DART_SUPPRESS_ANALYTICS='true'
C:\Users\tutic\Flutter\flutter\bin\flutter.bat analyze
```

## Web 构建

```powershell
cd final_assignment_front
$env:DART_SUPPRESS_ANALYTICS='true'
C:\Users\tutic\Flutter\flutter\bin\flutter.bat build web
```

## 主题

主题配置集中在：

```text
lib/config/themes/app_theme.dart
```

侧边栏设置入口提供主题切换和缓存清理。登录页、管理员端、驾驶员端和业务详情页应保持同一套主题 token。

## API 约定

- 默认后端地址由前端 API 配置读取，本地通常指向 `http://localhost:8080`
- 驾驶员端接口必须以当前登录账号绑定的司机档案为边界
- 管理员端接口需要 `ADMIN` 或 `SUPER_ADMIN`
- 超级管理员功能需要 `SUPER_ADMIN`

## UI 约束

- 不再使用粒子背景，避免 GPU 或核显占用飙升
- 业务页面统一使用同一套错误、空状态、加载状态和过滤栏样式
- 可折叠侧边栏展开/收起时应避免白条、布局跳动和大块空白
- 小屏页面优先保持内容可滚动，不让组件溢出到 Flutter 红屏
