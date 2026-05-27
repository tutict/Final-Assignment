# React Frontend

`final_assignment_front_react` 是保留的 React + Vite 管理端实现，用于对比 Flutter 前端和验证后台管理页面的 Web 技术路线。

当前主线目检和联调优先使用 Flutter Web；React 版本保留登录、鉴权、路由、基础后台页面和 API 封装能力。

## 开发

```bash
npm install
npm run dev
```

默认后端地址为：

```text
http://localhost:8081
```

可通过 `.env` 覆盖：

```env
VITE_API_BASE_URL=http://localhost:8080
```

## 构建

```bash
npm run build
```

## 定位

- React 版本用于保留管理端 Web 实现和前端架构对比
- Flutter 版本是当前主要展示和联调入口
- 新业务能力优先在 Flutter 端补齐，再按需要同步到 React 端
