# 后端包结构说明

Spring Boot 主后端按“领域归属优先，框架分层其次”的原则组织。目标是让交通业务、后台管理、审计日志、AI/RAG 和共享基础设施各自收口，避免所有代码继续堆在同一层级里。

## 总体原则

- 业务概念优先：驾驶员、车辆、违法、罚款、扣分、申诉、日志、RAG 等代码按领域归属放置。
- 框架细节后置：Controller、Service、Mapper、Entity 仍保留框架分层，但包名要体现所属领域。
- 共享能力集中：幂等、敏感数据、CDC、Elasticsearch、Kafka 公共处理器放在共享基础设施包，不散落到各业务模块。
- 角色边界清晰：普通管理员处理业务，超级管理员处理日志、RAG、系统治理等高风险能力。

## Controller 层

| 包 | 职责 |
| --- | --- |
| `controller.auth` | 登录、注册、刷新令牌、退出登录、当前用户信息 |
| `controller.admin` | 用户、角色、权限、系统配置、备份还原等后台管理接口 |
| `controller.business` | 驾驶员、车辆、违法、罚款、扣分、缴费、申诉、进度、工作流等业务接口 |
| `controller.audit` | 操作日志、登录日志、系统日志、请求历史详情 |
| `controller.rag` | RAG 资料录入、文件上传、索引、回填、向量化和文档管理 |
| `controller.view` | 面向前端的只读聚合视图接口 |
| `ai.chat` | AI Chat HTTP/SSE 接口和 agent action 编排入口 |

Controller 只负责协议适配、鉴权注解、请求校验和响应包装。复杂业务规则应下沉到应用服务或领域服务。

## Service 层

| 包 | 职责 |
| --- | --- |
| `service.auth` | JWT、刷新令牌、黑名单、登录注册、当前用户画像 |
| `service.admin` | 系统用户、角色、权限、配置、备份任务 |
| `service.appeal` | 申诉记录和申诉审核 |
| `service.driver` | 驾驶员档案、车辆信息、驾驶员车辆绑定 |
| `service.offense` | 违法记录、违法类型、扣分、罚款 |
| `service.payment` | 缴费记录和缴费状态 |
| `service.audit` | 登录日志、操作日志、系统日志 |
| `service.ai` | AI 聊天、联网搜索、工具调用适配 |
| `service.messaging` | Kafka、WebSocket/SSE、业务进度推送 |
| `service.system` | 请求历史、幂等记录和系统支撑服务 |

Service 层应保持事务边界清楚。跨表组合查询可以放在专门的业务视图服务中，避免 Controller 直接拼装多个 Mapper。

## AI 与 RAG

| 包 | 职责 |
| --- | --- |
| `ai.chat` | 聊天编排、流式输出、provider 调度、agent action |
| `ai.prompt` | 驾驶员、普通管理员、超级管理员的 agent 约束和角色解析 |
| `ai.rag` | 查询时检索、ACL 过滤、重排、prompt 上下文、embedding 检索 |
| `rag.config` | RAG 索引和任务配置 |
| `rag.ingestion` | 数据库源抽取、上传文件解析、PDF/DOCX/XLSX 等格式处理 |
| `rag.chunk` | 文本分块和 chunk 规范化 |
| `rag.indexing` | 回填任务、索引编排、alias 切换 |
| `rag.service` | RAG 文档、chunk、embedding task 的持久化服务 |
| `rag.entity` / `rag.mapper` | RAG MySQL 表对应的实体和 Mapper |

当前 RAG 上传解析支持 `txt`、`md`、`csv`、`tsv`、`json`、`docx`、`xlsx` 和文本型 `pdf`。扫描版 PDF 需要先 OCR。

## 持久化层

`entity.*` 与 `mapper.*` 按相同领域拆分：

- `admin`：系统用户、角色、权限、配置、备份
- `appeal`：申诉记录、申诉审核
- `audit`：登录日志、操作日志
- `auth`：认证和令牌相关实体
- `driver`：驾驶员、车辆、车辆绑定
- `offense`：违法、违法类型、罚款、扣分
- `payment`：缴费记录
- `system`：请求历史、系统支撑数据

Elasticsearch 文档保留在 `entity.elastic`，因为它们是搜索读模型，不是 MySQL 主实体。RAG 使用 `rag.entity` 和 `rag.mapper`，因为它属于 AI 知识库子系统。

## 配置层

| 包 | 职责 |
| --- | --- |
| `config.security` / `config.login.jwt` | JWT、鉴权、CORS、角色边界 |
| `config.db` | 数据库启动检查、结构补齐、敏感字段回填 |
| `config.shell` | 本地 Docker、Ollama 等启动脚本集成 |
| `config.ai` | AI provider、RAG 检索和向量化配置 |
| `config.kafka` | Kafka topic、consumer、listener 基础配置 |
| `config.elasticsearch` / `elasticsearch` | ES client、索引、搜索文档转换 |

配置类只负责装配，不应承载业务流程。业务默认值应尽量收口到属性类或专门的配置对象。

## 共享基础设施

| 包 | 职责 |
| --- | --- |
| `common.idempotency` | HTTP 幂等请求和 Kafka 消息幂等执行器 |
| `config.security.SecurityRoleUtils` | 角色判断和 Spring Security authority 边界处理 |
| `cdc` | MySQL CDC 到 Elasticsearch 的同步消费 |
| `elasticsearch` | 搜索索引、文档投影、模糊搜索支持 |
| `sensitive` / `config.db` 相关类 | 敏感字段加密、blind-index、历史数据回填 |

Kafka Listener 默认应使用 `IdempotentKafkaMessageProcessor`。只有违法、缴费等确实需要领域治理逻辑的监听器，才在委托幂等处理前后保留额外业务步骤。

## 角色命名

- 应用层统一使用 `USER`、`ADMIN`、`SUPER_ADMIN` 等规范角色名。
- `USER` 表示驾驶员端用户。
- `ADMIN` 表示普通业务管理员，负责交通违法处理业务。
- `SUPER_ADMIN` 表示技术治理管理员，负责日志审查、RAG 管理、系统配置、权限治理和高风险操作。
- 历史上的 `ROLE_ADMIN` 只应在兼容边界被归一化为 `ADMIN`，业务代码不要继续新增 `ROLE_ADMIN` 分支。
- Spring Security 的 `ROLE_` 前缀由 `SecurityRoleUtils` 或认证边界处理，业务代码不要硬编码带前缀的 authority。

## 敏感字段规则

身份证号、手机号、银行卡号等敏感字段在存在 blind-index 后，不应再新增明文等值查询。新代码按以下优先级处理：

1. 仅在兼容旧表结构确有必要时保留明文字段。
2. 通过敏感数据持久化服务写入 `*_ciphertext`。
3. 通过 `*_blind_index` 做精确查询。
4. 对前端、日志、Elasticsearch 和 AI/RAG 上下文只暴露脱敏值或低风险字段。

## 新增代码放置建议

| 新能力 | 推荐位置 |
| --- | --- |
| 新业务接口 | `controller.business` + 对应 `service.<domain>` |
| 新后台治理接口 | `controller.admin` 或 `controller.audit` |
| 超级管理员 RAG 能力 | `controller.rag` + `rag.*` |
| AI agent 动作 | `ai.chat` / `ai.prompt`，必要时调用领域 Service |
| 搜索读模型 | `elasticsearch` + `entity.elastic` |
| CDC 同步 | `cdc` |
| Kafka 消费幂等 | `common.idempotency` + 对应 listener |
| 敏感字段改造 | `config.db` / 敏感数据服务 / 对应 Mapper 查询改造 |

如果一个类同时跨多个领域，优先判断它是“业务聚合视图”还是“共享基础设施”。前者放在业务视图服务，后者放入共享包并保持无业务偏向。
