# Phase 3-7 实施指南

本指南涵盖剩余的 Phase 3-7，共约 73 个文件。

---

## Phase 3: AI 基础设施增强（~30 文件）

**目标位置**：`finalassignmentcloud-ai/`

**优先级**：🟡 中（当前 AI 基本可用，这是增强）

### 3.1 AI Provider 抽象层（~10 文件）

**当前状态**：直接使用 OllamaChatModel

**目标状态**：多提供商支持

**文件清单**：
```
ai/provider/AiProvider.java                    - 提供商接口
ai/provider/AiProviderRegistry.java            - 提供商注册表
ai/provider/OllamaAiProvider.java              - Ollama 实现
ai/provider/OpenAiCompatibleProvider.java      - OpenAI 兼容实现
ai/provider/MockAiProvider.java                - Mock 实现（测试用）
ai/provider/NoopAiProvider.java                - 空实现
ai/provider/health/AiProviderHealthIndicator.java - 健康检查
ai/provider/model/AiMessage.java               - 消息抽象
ai/provider/model/AiChatPrompt.java            - 提示抽象
ai/provider/model/AiGenerationOptions.java     - 生成选项
ai/provider/model/AiToken.java                 - Token 抽象
```

**移植步骤**：
1. 提取 Provider 接口和抽象类
2. 移植 Ollama 实现（保持现有功能）
3. 添加 OpenAI 实现（可选）
4. 集成到现有 ChatAgent

**配置示例**：
```yaml
ai:
  provider:
    default: ollama
    ollama:
      base-url: http://localhost:11434
    openai:
      api-key: ${OPENAI_API_KEY}
      model: gpt-4
```

### 3.2 Chat Pipeline & Orchestration（~8 文件）

**文件清单**：
```
ai/chat/ChatPipeline.java                - 聊天流程编排
ai/chat/ChatStreamService.java           - 流式响应服务
ai/chat/StreamEventWriter.java           - SSE 事件写入器
ai/chat/AiChatService.java               - 聊天服务协调
ai/chat/context/ContextBuilder.java      - 上下文构建器
ai/chat/context/MessageHistory.java      - 消息历史
ai/chat/context/ConversationContext.java - 会话上下文
ai/chat/response/ResponseFormatter.java  - 响应格式化
```

**当前状态**：
- ✅ ChatAgent 已存在
- ✅ 基础流式支持已实现
- ⚠️ 缺少高级上下文管理

**增强点**：
- 多轮对话上下文管理
- 流式响应优化
- 响应格式化增强

### 3.3 Prompt Management（~7 文件）

**已完成**：
- ✅ AgentConstraintService
- ✅ AiAgentRoleResolver
- ✅ 策略文件（driver.md, admin.md, super_admin.md）

**待添加**：
```
ai/prompt/PromptAssembler.java           - 提示组装器
ai/prompt/PromptTemplateService.java     - 模板服务
ai/prompt/template/PromptTemplate.java   - 模板定义
ai/prompt/variable/VariableResolver.java - 变量解析器
```

### 3.4 Search & Actions（~5 文件）

**文件清单**：
```
ai/action/ChatActionRuleEngine.java      - 动作规则引擎
ai/search/AIChatSearchService.java       - 搜索集成服务
ai/search/crawler/baidu_crawler.py       - 百度爬虫（Python）
ai/search/crawler/baidu_crawler_scrapy.py - Scrapy版本（Python）
ai/action/registry/ActionRegistry.java    - 动作注册表
```

**注意**：Python 爬虫需要 GraalPy 环境

---

## Phase 4: 治理框架（~15 文件）

**目标位置**：`finalassignmentcloud-common/governance/`

**优先级**：🟡 中（数据变更协调）

### 4.1 核心治理（~6 文件）

**文件清单**：
```
governance/core/AfterCommitBoundary.java          - 事务后边界
governance/core/EventIntentClassifier.java        - 事件意图分类器
governance/core/GovernanceVocabulary.java         - 治理词汇表
governance/core/MutationSideEffectPolicy.java     - 变更副作用策略
governance/core/SemanticMutationType.java         - 语义变更类型
governance/core/SideEffectCoordinator.java        - 副作用协调器
```

**用途**：
- 协调跨域数据变更
- 管理副作用
- 确保事务一致性

### 4.2 领域特定治理（~9 文件）

**Offense 治理**：
```
offense/governance/OffenseGovernanceClassifier.java
offense/governance/OffenseEventIntent.java
offense/governance/OffenseMutationCoordinator.java
```

**Payment 治理**：
```
payment/governance/PaymentGovernanceClassifier.java
payment/governance/PaymentEventIntent.java
payment/governance/PaymentMutationCoordinator.java
```

**其他领域**：类似模式

**依赖**：
- 核心治理组件
- 领域服务
- 事件发布器

---

## Phase 5: 搜索与 CDC 基础设施（~5 文件）

**目标位置**：`finalassignmentcloud-search/` 或 `finalassignmentcloud-common/`

**优先级**：🟡 中（实时搜索同步）

### 5.1 MySQL CDC to Elasticsearch（~3 文件）

**文件清单**：
```
search/cdc/MysqlCdcElasticsearchIndexer.java     - CDC 索引器
search/cdc/CdcEventHandler.java                  - CDC 事件处理器
search/cdc/TableChangeListener.java              - 表变更监听器
```

**功能**：
- 监听 MySQL binlog
- 实时更新 Elasticsearch 索引
- 确保搜索一致性

**依赖**：
```xml
<dependency>
    <groupId>com.github.shyiko</groupId>
    <artifactId>mysql-binlog-connector-java</artifactId>
</dependency>
```

### 5.2 Elasticsearch 配置增强（~2 文件）

**来源**：commit 46d9ad7

**文件**：
- Elasticsearch settings JSON
- 改进的分析器配置
- 模糊搜索优化

---

## Phase 6: 数据库迁移（~3 文件）

**目标位置**：`finalassignmentcloud-common/config/db/`

**优先级**：🟢 低（架构完善）

### 已完成
- ✅ SensitiveDataSchemaMigration

### 待添加

**文件清单**：
```
config/db/RagSchemaMigration.java              - RAG 表结构迁移
config/db/RequestHistorySchemaMigration.java   - 请求历史迁移
config/db/AccountDriverSchemaMigration.java    - 账户驾驶员关联（完善）
```

**模式**：
```java
@Component
public class RagSchemaMigration implements InitializingBean {
    private final DataSource dataSource;
    private final JdbcTemplate jdbcTemplate;
    
    @Override
    public void afterPropertiesSet() {
        // 检查表是否存在
        // 如果不存在，创建表
        // 如果存在，检查并添加缺失的列
    }
}
```

---

## Phase 7: 业务服务与 DTOs（~20 文件）

**目标位置**：各个微服务模块

**优先级**：🟢 低（功能增强）

### 7.1 业务服务（~8 文件）

**文件清单**：
```
service/business/BusinessRecordViewService.java   - 业务记录视图服务
service/offense/OffenseDetailService.java         - 违章详情服务
service/driver/DriverSummaryService.java          - 驾驶员汇总服务
service/vehicle/VehicleDetailService.java         - 车辆详情服务
service/payment/PaymentSummaryService.java        - 支付汇总服务
service/workflow/WorkflowOrchestrator.java        - 工作流编排器
service/notification/NotificationService.java     - 通知服务
service/report/ReportGenerator.java               - 报表生成器
```

### 7.2 DTOs（~12 文件）

**分类**：
- AI 相关 DTO
- 业务视图 DTO
- 治理相关 DTO
- 报表相关 DTO

**示例**：
```java
// AI Chat DTOs
dto/ai/AdvancedChatRequest.java
dto/ai/ChatHistoryResponse.java
dto/ai/ContextAwareChatRequest.java

// Business View DTOs
dto/business/DriverBusinessView.java
dto/business/VehicleBusinessView.java
dto/business/OffenseBusinessView.java

// Governance DTOs
dto/governance/MutationEvent.java
dto/governance/SideEffectDescriptor.java
```

---

## 实施优先级矩阵

| Phase | 文件数 | 优先级 | 依赖 | 预计时间 |
|-------|--------|--------|------|----------|
| **Phase 2: Appeal DDD** | 38 | 🔴 高 | Common, System | 2-3h |
| **Phase 3: AI 增强** | 30 | 🟡 中 | AI service | 2-3h |
| **Phase 4: 治理框架** | 15 | 🟡 中 | Common, Services | 1-2h |
| **Phase 5: 搜索 CDC** | 5 | 🟡 中 | Search, Common | 1h |
| **Phase 6: 数据库迁移** | 3 | 🟢 低 | Common | 0.5h |
| **Phase 7: 业务服务** | 20 | 🟢 低 | All services | 1-2h |

**总计**：111 文件，8-12 小时

---

## 推荐实施策略

### 策略 A：按需实施（推荐）✅

**适用场景**：生产环境，按业务需求驱动

**步骤**：
1. 评估每个 Phase 对当前业务的必要性
2. 优先实施影响当前功能的模块
3. 其他模块作为技术债务记录

**示例决策树**：
```
需要 Appeal 功能？
├─ 是 → 立即实施 Phase 2
└─ 否 → 延后

需要多 AI 提供商？
├─ 是 → 实施 Phase 3.1
└─ 否 → 当前够用

需要跨域数据协调？
├─ 是 → 实施 Phase 4
└─ 否 → 延后
```

### 策略 B：分批并行实施

**适用场景**：团队人力充足

**分工**：
- 团队 A：Phase 2 (Appeal)
- 团队 B：Phase 3 (AI)
- 团队 C：Phase 4-7 (基础设施)

### 策略 C：完整迁移

**适用场景**：充足时间，追求完整性

**顺序**：Phase 2 → 4 → 3 → 5 → 6 → 7

---

## 快速参考

### 批量提取命令模板

```bash
# 提取单个文件
git show main:finalAssignmentBackend/src/main/java/com/tutict/finalassignmentbackend/PATH/FILE.java > /tmp/FILE.java

# 修改包名
sed -i 's/finalassignmentbackend/finalassignmentcloud.TARGET/g' /tmp/FILE.java

# 复制到目标
cp /tmp/FILE.java finalAssignmentCloud/TARGET_MODULE/src/main/java/...
```

### 编译验证

```bash
# 编译单个模块
mvn compile -DskipTests -f finalAssignmentCloud/pom.xml -pl finalassignmentcloud-TARGET

# 编译所有模块
mvn compile -DskipTests -f finalAssignmentCloud/pom.xml
```

### 依赖检查

```bash
# 检查缺失的类引用
grep -r "import com.tutict.finalassignmentbackend" finalAssignmentCloud/finalassignmentcloud-TARGET/src

# 列出所有编译错误
mvn compile -f finalAssignmentCloud/pom.xml 2>&1 | grep ERROR
```

---

## 完成检查清单

### ✅ Phase 3: AI 基础设施
- [ ] AI Provider 抽象层可切换提供商
- [ ] 流式响应稳定
- [ ] 上下文管理正常
- [ ] 搜索集成工作

### ✅ Phase 4: 治理框架
- [ ] 事务后边界正常执行
- [ ] 副作用协调器工作
- [ ] 领域治理规则生效

### ✅ Phase 5: 搜索 CDC
- [ ] CDC 监听 binlog
- [ ] Elasticsearch 实时更新
- [ ] 搜索结果一致

### ✅ Phase 6: 数据库迁移
- [ ] 所有迁移脚本执行成功
- [ ] 表结构正确
- [ ] 数据回填完成

### ✅ Phase 7: 业务服务
- [ ] 业务服务可调用
- [ ] DTOs 序列化正常
- [ ] 端点测试通过

---

## 支持文档

相关文档：
- `SPRING_CLOUD_SYNC_SUMMARY.md` - 初始同步总结
- `PHASE1_TEST_REPORT.md` - Phase 1 测试报告
- `PHASE2_APPEAL_MIGRATION_GUIDE.md` - Phase 2 详细指南
- `SYNC_SUMMARY_AND_NEXT_STEPS.md` - 总体规划

---

## 总结

Phase 3-7 提供了系统的增强和完善：
- **Phase 3**: AI 能力提升
- **Phase 4**: 数据治理
- **Phase 5**: 搜索优化
- **Phase 6**: 架构完善
- **Phase 7**: 功能丰富

根据实际业务需求选择性实施，确保每个 Phase 的投入产出比。

祝实施顺利！🎯
