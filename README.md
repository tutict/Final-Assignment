# 交通违法行为处理管理系统

面向交通违法处理、驾驶员服务和后台监管的全栈工程项目。项目最初来自毕业设计，当前已经按更工程化的方向持续演进：后端以 Spring Boot 单体为主线，同时保留 Spring Cloud、Go、Quarkus 等实现作为架构实验；前端以 Flutter Web 为主要联调入口。

当前主线关注点不再只是 CRUD 展示，而是围绕真实业务链路补齐权限、幂等、消息、检索、RAG、敏感数据保护和本地一键启动能力。

## 快速导航

| 入口 | 说明 |
| --- | --- |
| [一键启动](#一键启动) | 启动 Docker 依赖、后端、Flutter Web 和本地 AI 环境 |
| [后端包结构](finalAssignmentBackend/PACKAGE_LAYOUT.md) | Spring Boot 主后端的分层、领域包和命名规则 |
| [数据库设计](database/DATABASE_DESIGN.md) | MySQL 表、角色、业务关联、敏感字段和 RAG 表设计 |
| [压测报告](docs/performance/load-test-2026-05-31.md) | k6 / wrk 本地性能基线、AI/RAG 分段压测和瓶颈分析 |
| [脚本说明](scripts/README.md) | 启动、Debezium、AI 链路测试等脚本参数 |

## 当前主线

| 模块 | 路径 | 状态 |
| --- | --- | --- |
| Spring Boot 主后端 | `finalAssignmentBackend` | 主线实现，承载认证、业务、审计、AI、RAG、CDC、ES |
| Flutter 前端 | `final_assignment_front` | 当前主要目检与联调入口，管理员端和驾驶员端共用 |
| React 前端 | `final_assignment_front_react` | 保留的管理端实现 |
| Spring Cloud 版本 | `finalAssignmentCloud` | 微服务拆分实验 |
| Go 版本 | `final_assignment_backend_go` | Go 后端实验 |
| Quarkus 版本 | `final_assignment_backend_quarkus` | Quarkus 后端实验 |

## 角色入口

| 角色 | 前端入口 | 主要职责 |
| --- | --- | --- |
| 驾驶员 | Flutter Web 驾驶员端 | 查看个人资料、违法详情、缴费、申诉、车辆登记、进度消息和地图 |
| 普通管理员 `ADMIN` | Flutter Web 管理端 | 处理驾驶员、车辆、违法、罚款、扣分、申诉等业务 |
| 超级管理员 `SUPER_ADMIN` | Flutter Web 管理端的技术治理入口 | 审查操作日志/登录日志、管理 RAG 资料、执行索引/回填等高风险操作 |

## 核心业务

- 管理员端：驾驶员、车辆、违法行为、罚款、扣分、申诉、日志、系统配置管理
- 驾驶员端：个人资料、违法详情、罚款缴纳、用户申诉、车辆登记、进度消息、地图入口
- 超级管理员端：操作日志审查、RAG 资料录入、知识库索引与回填管理
- AI 助手：驾驶员常见问题、管理员业务辅助、RAG 检索增强问答、前端页面跳转/填单能力探索
- 实时链路：WebSocket/SSE、Kafka 异步消息、死信监听、业务进度推送

## 工程化能力

- `Spring Security + JWT + BCrypt` 认证授权
- `ADMIN` 与 `SUPER_ADMIN` 角色边界，普通管理员负责业务处理，超级管理员负责日志与 RAG 管理
- `MyBatis Plus + MySQL` 核心数据访问
- `Redis + Caffeine` 多级缓存
- `Kafka / Redpanda` 异步事件、审计与幂等处理
- `Debezium + Kafka Connect` 捕获 MySQL binlog，异步同步到 Elasticsearch
- `Elasticsearch` 作为搜索读模型，避免将敏感明文直接写入搜索索引
- `Ollama + Spring AI / LangChain4j + GraalPy` 支持本地 AI、联网搜索和 Python 脚本能力
- `RAG` 支持手工录入、文档上传、表格上传、PDF 文本解析、分块、索引任务和检索
- 敏感字段支持 `AES-GCM` 密文列与 `HMAC blind-index` 查询列
- 统一 Kafka Listener 幂等处理器，减少重复反序列化、重复请求判断、成功/失败历史标记代码

## 架构速览

```text
Flutter Web
  -> Spring Security + JWT
  -> Spring Boot 业务 API
  -> MyBatis Plus + MySQL
  -> Redis / Caffeine
  -> Redpanda(Kafka API) + Debezium
  -> Elasticsearch 搜索读模型
  -> Ollama / GraalPy / RAG
```

主线后端按“领域归属优先、框架分层其次”的方式组织：认证、业务、审计、管理、AI/RAG、CDC、搜索和共享基础设施各自收口。详细包结构见 [finalAssignmentBackend/PACKAGE_LAYOUT.md](finalAssignmentBackend/PACKAGE_LAYOUT.md)。

## 压测与性能基线

- [2026-05-31 k6 / wrk 压测报告](docs/performance/load-test-2026-05-31.md)
- [2026-05-31 Kafka / Redpanda 专项压测报告](docs/performance/kafka-load-test-2026-05-31.md)
- [2026-05-30 k6 / wrk 压测报告](docs/performance/load-test-2026-05-30.md)
- 一键压测编排脚本位于 `scripts/performance/run-load-tests.ps1`
- k6 脚本位于 `scripts/k6/`，wrk Lua 脚本位于 `scripts/wrk/`

## 一键启动

推荐从仓库根目录使用脚本启动。

Windows:

```bat
scripts\start-all.bat
```

Linux / macOS:

```sh
sh scripts/start-all.sh
```

默认会尝试启动：

1. Docker Desktop / Docker 服务
2. `scripts/dev-compose.yml` 中的本地依赖
3. Ollama
4. Spring Boot 后端
5. Flutter Web 前端，默认访问 `http://127.0.0.1:3000`

如只启动前后端，可跳过 Docker/Ollama：

```bat
set START_LOCAL_SERVICES=false
scripts\start-all.bat
```

更多启动参数见 [scripts/README.md](scripts/README.md)。

## 本地依赖

主线开发建议准备：

- JDK 23 或 25
- Maven 3.9+
- Flutter 3+
- Docker Desktop
- 本地 MySQL 8.0+
- Ollama

`scripts/dev-compose.yml` 提供：

- Redis
- Redpanda
- Elasticsearch 9.4.1
- Debezium Connect

Elasticsearch 默认使用 Elastic 官方 GA 9.4.1。后端 Java client 由 Spring Boot 4.0.1 管理为 `elasticsearch-java 9.2.2`，可连接同主版本更高 minor 的服务端；如果需要调用 9.4 专属强类型 API，再单独升级客户端依赖。需要验证其他版本时，可用 `ELASTICSEARCH_IMAGE=docker.elastic.co/elasticsearch/elasticsearch:<version>` 覆盖本地镜像。

MySQL 默认按本机服务使用，连接库名为 `traffic`。密码、JWT、AI、加密密钥等通过环境变量注入。

## 关键环境变量

后端常用配置：

```properties
DB_USERNAME=root
DB_PASSWORD=your_password
BACKEND_URL=http://localhost:8080
JWT_SECRET=replace_with_a_real_secret
```

AI/RAG：

```properties
OLLAMA_ENABLED=true
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2
RAG_ENABLED=true
RAG_INDEXING_ENABLED=true
RAG_EMBEDDING_ENABLED=true
RAG_EMBEDDING_PROVIDER=ollama
RAG_EMBEDDING_MODEL=nomic-embed-text
RAG_EMBEDDING_DIMENSIONS=768
RAG_RETRIEVAL_ENABLED=true
```

敏感字段加密与 blind-index：

```properties
SENSITIVE_DATA_ENCRYPTION_ENABLED=true
SENSITIVE_DATA_ENCRYPTION_KEY=<base64-32-byte-key-or-strong-secret>
SENSITIVE_DATA_BLIND_INDEX_KEY=<separate-base64-32-byte-key-or-strong-secret>
```

CDC 到 Elasticsearch：

```properties
CDC_ELASTICSEARCH_ENABLED=true
CDC_ELASTICSEARCH_TOPIC_PATTERN=traffic\.traffic\.(driver_information|vehicle_information|sys_user)
```

## MySQL CDC 到 Elasticsearch

当前搜索同步链路：

```text
MySQL binlog
  -> Debezium Connect
  -> Redpanda(Kafka API)
  -> Spring Boot CDC Consumer
  -> Elasticsearch
```

本地 MySQL 需要开启 row-based binlog：

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

启动依赖并注册连接器：

```powershell
docker compose -f scripts\dev-compose.yml up -d redpanda elasticsearch debezium-connect
$env:MYSQL_CDC_PASSWORD='change_this_password'
powershell -ExecutionPolicy Bypass -File scripts\debezium\register-mysql-cdc.ps1
```

## 敏感数据治理

身份证号、手机号、银行卡号等敏感数据采用三层处理：

- MySQL 原业务列保留兼容旧逻辑
- 新增 `*_ciphertext` 列保存密文
- 新增 `*_blind_index` 列用于精确查询

后端启动时会通过 `SensitiveDataSchemaMigration` 检查并补齐密文字段、blind-index 字段和索引，然后对历史明文数据回填密文与 blind-index。查询层优先使用 blind-index 精确匹配，避免继续依赖明文等值查询。

Elasticsearch 文档只写入脱敏展示值或低风险字段，不写入完整身份证号、手机号和银行卡号。

## RAG 资料录入

超级管理员可以通过 RAG 管理接口录入资料：

- 手工文本
- Markdown / TXT
- CSV / TSV / JSON
- DOCX
- XLSX
- PDF 文本型文件

当前 PDF 解析基于 PDFBox，只支持可提取文本的 PDF；扫描版图片 PDF 需要先 OCR。

资料入库后会写入 `rag_document` 和 `rag_chunk`，同时为每个 chunk 创建 `rag_embedding_task`。默认 embedding provider 为 Ollama `nomic-embed-text`，后台定时任务会把待处理 chunk 转为向量并写入 Elasticsearch `rag_chunk_current` alias，MySQL 侧只记录 `embedding_model`、`embedding_hash` 和处理状态。首次使用前需要先准备模型：

```powershell
ollama pull nomic-embed-text
```

如需手动触发一批向量化任务，可由超级管理员调用：

```text
POST /api/rag/admin/embedding/run?limit=25
```

RAG 数据表定义见：

- `finalAssignmentBackend/src/main/resources/rag/rag_schema.sql`

## 后端包结构

后端已经从单纯的平铺包逐步拆成按领域归属组织的结构。详细说明见：

- [finalAssignmentBackend/PACKAGE_LAYOUT.md](finalAssignmentBackend/PACKAGE_LAYOUT.md)

## 数据库设计

数据库设计文档已按当前业务域重新整理：

- [database/DATABASE_DESIGN.md](database/DATABASE_DESIGN.md)

重点关系：

- `sys_user` 统一承载驾驶员用户、普通管理员、超级管理员账号
- 驾驶员账号通过 `driver_information.user_id` 关联司机档案
- 车辆通过 `driver_vehicle` 与驾驶员建立多对多绑定
- 违法、罚款、扣分、申诉围绕 `offense_record` 串联
- RAG 使用独立的 `rag_document`、`rag_chunk`、`rag_embedding_task`，向量写入 Elasticsearch `rag_chunk_current`

## 验证命令

后端编译：

```powershell
cd finalAssignmentBackend
mvn -q -DskipTests test
```

后端测试默认使用本地 MySQL `traffic_test`，可通过 `TEST_DB_URL`、`TEST_DB_USERNAME`、`TEST_DB_PASSWORD` 覆盖连接信息：

```powershell
cd finalAssignmentBackend
mvn -q test
```

Flutter 静态检查：

```powershell
cd final_assignment_front
$env:DART_SUPPRESS_ANALYTICS='true'
C:\Users\tutic\Flutter\flutter\bin\flutter.bat analyze
```

Flutter Web 构建：

```powershell
cd final_assignment_front
$env:DART_SUPPRESS_ANALYTICS='true'
C:\Users\tutic\Flutter\flutter\bin\flutter.bat build web
```

AI 链路冒烟测试：

```powershell
powershell -ExecutionPolicy Bypass -File scripts\test-ai-chain.ps1
```

## 当前工程状态

- 主展示链路：`finalAssignmentBackend` + `final_assignment_front`
- 普通管理员与驾驶员端 UI 已统一暗色/亮色主题、侧边栏、AI 助手入口和业务页面样式
- 司机档案、用户账户、车辆、违法、罚款、扣分、申诉的多表关联已经补齐主线查询
- Kafka Listener 幂等样板已集中到公共处理器
- 复杂治理监听器保留原业务审计语义后完成收口
- RAG 已支持手工录入、多格式文件解析、chunk 向量化和 Elasticsearch 混合检索
- 敏感字段密文列、blind-index 字段、查询改造和历史回填已经落地

## 注意事项

- 不要提交真实数据库密码、JWT 密钥、AI API Key 或加密密钥
- 本地开发可用弱密钥，演示或生产必须使用独立强密钥
- PDF RAG 当前不支持加密 PDF 和纯图片扫描 PDF
- CDC 同步依赖 MySQL binlog 配置，未开启时不会有增量同步
