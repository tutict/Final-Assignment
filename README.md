# 交通违法处理管理系统

一个面向交通违法业务场景的全栈项目，覆盖违法信息管理、罚款处理、扣分管理、申诉流程、日志审计、权限控制等核心能力。项目最初来源于毕业设计，后续持续迭代，逐步扩展为包含单体、微服务、轻量框架和多端前端在内的综合性工程实践。

目前仓库以 `Spring Boot + React / Flutter` 作为主要展示链路，同时保留 `Quarkus`、`Go`、`Spring Cloud` 等版本，用于架构演进和技术验证。

## 项目概览

- 项目类型：个人独立开发的全栈作品集项目
- 业务方向：交通违法处理与后台管理
- 主要能力：后端架构设计、权限与安全、缓存与消息、跨端前端实现、工程化落地

## 核心功能

- 用户、角色、权限管理
- 驾驶员、车辆、违法信息、罚款信息管理
- 扣分处理与申诉处理流程
- 登录日志、操作日志、系统日志审计
- 数据备份与恢复
- 检索、实时消息、WebSocket 通信能力
- 基于本地模型的 AI 问答与辅助查询探索
- 基于 Debezium 的 MySQL CDC、Kafka/Redpanda 与 Elasticsearch 搜索同步链路

## 承担内容

- 独立完成系统需求拆解、数据库设计与模块划分
- 独立完成后端接口开发、权限认证、缓存设计、消息通信和部分状态流转建模
- 独立完成 Flutter 与 React 两套前端界面及接口联调
- 维护多套后端实现方案，用于对比单体、轻量化和微服务架构的实现差异
- 完成 Docker/Testcontainers 驱动的本地依赖管理与开发环境搭建

## 关键技术实现

- 使用 `Spring Security + JWT + BCrypt` 构建认证与授权链路
- 使用 `MyBatis Plus + MySQL` 实现核心业务数据访问
- 使用 `Redis + Caffeine` 实现多级缓存，降低热点数据访问开销
- 使用 `Kafka` 支撑日志、审计和异步消息处理场景
- 使用 `Debezium + Kafka Connect` 捕获 MySQL binlog，推动 Elasticsearch 搜索读模型异步更新
- 使用 `WebSocket` 支撑实时通信能力
- 使用 `Testcontainers` 管理 Redis、Kafka/Redpanda、Elasticsearch 等本地依赖
- 在部分业务流程中引入状态机建模，提升流程可维护性
- 对身份证号、手机号、银行卡号等敏感字段执行展示脱敏，并预留 `AES-GCM + HMAC blind index` 的密文存储改造路径
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

## 工程化搜索同步

主线版本正在从“应用启动时全量同步 Elasticsearch”演进为更工程化的 CDC 搜索同步架构：

```text
MySQL binlog
    -> Debezium / Kafka Connect
    -> Redpanda(Kafka API)
    -> Spring Boot CDC Consumer
    -> Elasticsearch
```

本地开发环境中，`scripts/dev-compose.yml` 已包含 `redpanda`、`elasticsearch` 和 `debezium-connect`。本地 MySQL 需要开启 row-based binlog：

```ini
[mysqld]
server-id=223344
log-bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
```

CDC 账号示例：

```sql
CREATE USER 'debezium'@'%' IDENTIFIED BY 'change_this_password';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
FLUSH PRIVILEGES;
```

启动 CDC 基础设施并注册连接器：

```powershell
docker compose -f scripts\dev-compose.yml up -d redpanda elasticsearch debezium-connect
$env:MYSQL_CDC_PASSWORD='change_this_password'
powershell -ExecutionPolicy Bypass -File scripts\debezium\register-mysql-cdc.ps1
```

后端通过以下环境变量启用 CDC 到 ES 的消费：

```properties
CDC_ELASTICSEARCH_ENABLED=true
CDC_ELASTICSEARCH_TOPIC_PATTERN=traffic\.traffic\.(driver_information|vehicle_information|sys_user)
```

当前第一阶段先覆盖 `driver_information`、`vehicle_information`、`sys_user` 三类核心搜索索引；后续可继续扩展到申诉、违法、罚款和扣分记录。

## 敏感数据治理

Elasticsearch 不应保存完整身份证号、手机号、银行卡号等敏感字段。当前 ES 文档转换层会写入脱敏值，用于界面展示和低风险检索；MySQL 仍作为真实数据源。

后端已预留敏感数据加密能力：

```properties
SENSITIVE_DATA_ENCRYPTION_ENABLED=true
SENSITIVE_DATA_ENCRYPTION_KEY=<base64-32-byte-key-or-strong-secret>
SENSITIVE_DATA_BLIND_INDEX_KEY=<separate-base64-32-byte-key-or-strong-secret>
```

完整落地路径是：先新增密文字段与 blind-index 字段，再回填历史明文数据，最后把身份证号、手机号等查询从明文 `LIKE/eq` 改为 blind-index 精确匹配。这样可以避免直接加密导致现有业务查询失效。

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

主线版本，用于承载完整业务流程与主要技术能力。

- 路径：`finalAssignmentBackend`
- 技术关键词：`Spring Boot 4`、`Spring Security`、`MyBatis Plus`、`Redis`、`Kafka`、`Elasticsearch`
- 工程特点：
  - 基于 JWT 的认证鉴权
  - 审计日志与业务日志拆分
  - 基于 Testcontainers 的中间件依赖管理
  - 引入状态机管理部分业务流程
  - 集成本地 AI 服务与 GraalPy 能力

### 2. React 管理端

用于后台管理系统展示，覆盖登录鉴权、角色路由、数据列表、表单、统计图表等典型后台能力。

- 路径：`final_assignment_front_react`
- 技术关键词：`React 18`、`Vite`、`React Router`、`React Query`、`Axios`
- 页面能力：
  - 登录与认证上下文管理
  - 基于角色的路由访问控制
  - 通用数据表格、检索、弹窗、表单组件
  - 面向管理员场景的多业务页面

### 3. Flutter 前端

用于多端客户端能力验证，体现移动端与跨端开发能力。

- 路径：`final_assignment_front`
- 技术关键词：`Flutter`、`GetX`、`WebSocket`、`SharedPreferences`
- 功能方向：
  - 登录与本地状态存储
  - 图表、地图、二维码等交互组件集成
  - 面向移动端的业务流程展示

### 4. Spring Cloud 微服务版本

用于体现从单体架构向微服务架构拆分的设计思路。

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

## 运行说明

### 环境准备

- JDK 23 / 25
- Maven 3.9+
- Node.js 18+
- Flutter 3+
- Go 1.24+
- Docker
- MySQL、Redis、Kafka/Redpanda、Elasticsearch、Ollama（按所选模块启用）

### 推荐查看路径

优先查看 `Spring Boot 单体后端 + React 管理端`，这也是当前最完整、最稳定的业务实现组合。

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


