# 交通违法处理管理系统

一个面向交通违法业务场景的全栈项目，覆盖违法信息管理、罚款处理、扣分管理、申诉流程、日志审计、权限控制等核心能力。该项目最初来源于毕业设计，后续持续演进为个人长期维护的工程化作品集，用于验证不同后端技术路线在同一业务域下的实现方式。

目前仓库以 `Spring Boot + React / Flutter` 作为主要展示链路，同时保留 `Quarkus`、`Go`、`Spring Cloud` 等版本，用于架构演进和技术验证。

## 项目定位

- 项目类型：个人独立开发的全栈作品集项目
- 业务方向：交通违法处理与后台管理
- 展示重点：后端架构设计、权限与安全、缓存与消息、跨端前端实现、工程化能力
- 适用场景：简历项目展示、面试项目讲解、GitHub 作品集展示

## 核心功能

- 用户、角色、权限管理
- 驾驶员、车辆、违法信息、罚款信息管理
- 扣分处理与申诉处理流程
- 登录日志、操作日志、系统日志审计
- 数据备份与恢复
- 检索、实时消息、WebSocket 通信能力
- 基于本地模型的 AI 问答与辅助查询探索

## 个人职责

- 独立完成系统需求拆解、数据库设计与模块划分
- 独立完成后端接口开发、权限认证、缓存设计、消息通信和部分状态流转建模
- 独立完成 Flutter 与 React 两套前端界面及接口联调
- 维护多套后端实现方案，用于对比单体、轻量化和微服务架构的实现差异
- 完成 Docker/Testcontainers 驱动的本地依赖管理与开发环境搭建

## 技术亮点

- 使用 `Spring Security + JWT + BCrypt` 构建认证与授权链路
- 使用 `MyBatis Plus + MySQL` 实现核心业务数据访问
- 使用 `Redis + Caffeine` 实现多级缓存，降低热点数据访问开销
- 使用 `Kafka` 支撑日志、审计和异步消息处理场景
- 使用 `WebSocket` 支撑实时通信能力
- 使用 `Testcontainers` 管理 Redis、Kafka/Redpanda、Elasticsearch 等本地依赖
- 在部分业务流程中引入状态机建模，提升流程可维护性
- 集成 `Ollama + Spring AI / LangChain4j + GraalPy`，探索本地模型与 Python 能力协同

## 技术栈

| 分层 | 技术方案 |
| --- | --- |
| 后端主线 | Spring Boot 4、Spring Security、MyBatis Plus、Redis、Kafka、WebSocket、Elasticsearch |
| 微服务演进 | Spring Cloud、Spring Cloud Alibaba、Gateway、OpenFeign、Nacos、ShardingSphere |
| 轻量后端探索 | Quarkus、Vert.x、MyBatis Plus、SmallRye JWT、Redis Cache、Reactive Messaging |
| Go 版本探索 | Gin、GORM、Redis、Kafka、Elasticsearch、WebSocket |
| 前端 | React 18、Vite、React Router、React Query、Axios |
| 客户端 | Flutter 3、GetX、WebSocket、图表与地图相关组件 |
| 工程能力 | Docker、Testcontainers、GraalVM、GraalPy、JMH |

## 仓库结构

```text
Final-Assignment
├─ finalAssignmentBackend             # Spring Boot 单体后端主版本
├─ finalAssignmentCloud               # Spring Cloud 微服务拆分版本
├─ final_assignment_backend_quarkus   # Quarkus 后端实验版本
├─ final_assignment_backend_go        # Go 后端实验版本
├─ final_assignment_front             # Flutter 前端
├─ final_assignment_front_react       # React 管理端
├─ database                           # 数据库设计文档
└─ finalAssignmentTools               # 工具脚本与辅助资源
```

## 主要模块说明

### 1. Spring Boot 单体后端

主线版本，适合作为项目讲解和运行演示的核心模块。

- 路径：`finalAssignmentBackend`
- 技术关键词：`Spring Boot 4`、`Spring Security`、`MyBatis Plus`、`Redis`、`Kafka`、`Elasticsearch`
- 工程特点：
  - 基于 JWT 的认证鉴权
  - 审计日志与业务日志拆分
  - 基于 Testcontainers 的中间件依赖管理
  - 引入状态机管理部分业务流程
  - 集成本地 AI 服务与 GraalPy 能力

### 2. React 管理端

用于后台管理系统展示，覆盖登录鉴权、角色路由、数据列表、表单、统计图表等常见后台能力。

- 路径：`final_assignment_front_react`
- 技术关键词：`React 18`、`Vite`、`React Router`、`React Query`、`Axios`
- 页面能力：
  - 登录与认证上下文管理
  - 基于角色的路由访问控制
  - 通用数据表格、检索、弹窗、表单组件
  - 面向管理员场景的多业务页面

### 3. Flutter 前端

用于多端客户端能力验证，适合展示跨端开发经验。

- 路径：`final_assignment_front`
- 技术关键词：`Flutter`、`GetX`、`WebSocket`、`SharedPreferences`
- 功能方向：
  - 登录与本地状态存储
  - 图表、地图、二维码等交互组件集成
  - 面向移动端的业务流程展示

### 4. Spring Cloud 微服务版本

用于展示从单体架构向微服务架构拆分的设计思路。

- 路径：`finalAssignmentCloud`
- 已拆分模块：
  - `gateway`
  - `auth`
  - `user`
  - `traffic`
  - `audit`
  - `system`
  - `search`
  - `ai`
- 技术关键词：`Spring Cloud Gateway`、`OpenFeign`、`Nacos`、`ShardingSphere`

### 5. Quarkus / Go 后端探索版本

用于验证同一业务域在不同技术路线下的实现方式，体现对框架特性和架构取舍的理解。

- Quarkus 路径：`final_assignment_backend_quarkus`
- Go 路径：`final_assignment_backend_go`
- 关注点：
  - 轻量化启动与开发效率
  - 异步处理与高性能组件组合
  - 不同语言生态下的业务建模方式

## 求职展示建议

如果将该项目写入简历，建议突出以下信息：

- 项目性质：个人独立完成的全栈管理系统项目
- 业务复杂度：覆盖权限、流程、缓存、日志、消息、检索、AI 集成等多个典型后台场景
- 技术深度：不仅实现单体系统，还进一步拆分微服务并尝试 Quarkus、Go 等技术路线
- 工程能力：具备多端开发、后端架构设计、依赖管理、运行环境搭建和持续迭代能力

可参考的简历表述：

> 独立设计并实现交通违法处理管理系统，采用 Spring Boot、React、Flutter 构建完整业务闭环，覆盖权限认证、违法处理、申诉流程、日志审计、缓存优化、消息通信等场景；在主线版本之外，进一步完成 Spring Cloud 微服务拆分，并基于 Quarkus、Go 对同一业务域进行了多技术路线验证。

## 运行说明

### 环境准备

- JDK 23 / 25
- Maven 3.9+
- Node.js 18+
- Flutter 3+
- Go 1.24+
- Docker
- MySQL、Redis、Kafka/Redpanda、Elasticsearch、Ollama（按所选模块启用）

### 推荐演示链路

优先运行 `Spring Boot 单体后端 + React 管理端`，这是最适合做项目展示和面试讲解的组合。

### 常用启动方式

Spring Boot 后端：

```bash
cd finalAssignmentBackend
mvn spring-boot:run
```

React 前端：

```bash
cd final_assignment_front_react
npm install
npm run dev
```

Flutter 前端：

```bash
cd final_assignment_front
flutter pub get
flutter run
```

Quarkus 后端：

```bash
cd final_assignment_backend_quarkus
.\gradlew quarkusDev
```

Go 后端：

```bash
cd final_assignment_backend_go
go run ./project/cmd/app
```

## 配置说明

- 运行前请根据本地环境补充各模块中的数据库、Redis、Kafka、Elasticsearch、JWT 等配置
- 涉及密钥和账号信息时，请使用本地配置文件或环境变量，不要将真实凭据提交到仓库
- 部分模块依赖 Docker/Testcontainers 自动拉起中间件，因此请确保 Docker 处于可用状态

## 当前状态

- `finalAssignmentBackend`、`final_assignment_front_react`、`final_assignment_front` 适合作为主展示内容
- `finalAssignmentCloud` 处于持续拆分与补充阶段
- `final_assignment_backend_quarkus`、`final_assignment_backend_go` 主要用于技术验证与架构探索

## 补充文档

- 数据库设计文档：`database/DATABASE_DESIGN.md`


