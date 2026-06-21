# Phase 2: Appeal DDD 模块移植指南

## 概述

Appeal 模块是一个完整的 DDD（领域驱动设计）实现，包含 38 个 Java 文件，实现了申诉记录的完整业务逻辑。

**目标位置**：`finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/appeal/`

**预计工作量**：2-3 小时

---

## 架构层次

### 1. Domain Layer（领域层）- 18 文件 ⭐ 首先移植

#### 1.1 Policy Metadata & Types（最底层）- 5 文件

**优先级**：🔴 最高（其他类依赖这些）

```
domain/policy/AppealCallerType.java          - 调用者类型枚举
domain/policy/AppealEventType.java           - 事件类型枚举
domain/policy/AppealCallerMetadata.java      - 调用者元数据
domain/policy/AppealEventMetadata.java       - 事件元数据
```

**移植步骤**：
1. 创建目录：`mkdir -p finalassignmentcloud-system/.../appeal/domain/policy`
2. 提取文件：`git show main:finalAssignmentBackend/.../AppealCallerType.java`
3. 修改包名：`com.tutict.finalassignmentbackend.appeal` → `com.tutict.finalassignmentcloud.system.appeal`
4. 复制到目标位置

**示例命令**：
```bash
git show main:finalAssignmentBackend/src/main/java/com/tutict/finalassignmentbackend/appeal/domain/policy/AppealCallerType.java > /tmp/AppealCallerType.java
# 修改包名
sed -i 's/finalassignmentbackend/finalassignmentcloud.system/g' /tmp/AppealCallerType.java
# 复制到目标位置
cp /tmp/AppealCallerType.java finalAssignmentCloud/finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/appeal/domain/policy/
```

#### 1.2 Domain Policies（策略层）- 10 文件

**优先级**：🔴 高（核心业务规则）

```
domain/policy/AppealBusinessPolicy.java          - 业务规则策略
domain/policy/AppealCallerIntentPolicy.java      - 调用者意图策略
domain/policy/AppealEventIntentPolicy.java       - 事件意图策略
domain/policy/AppealFieldMutationPolicy.java     - 字段变更策略
domain/policy/AppealQueryPolicy.java             - 查询策略
domain/policy/AppealTransitionPolicy.java        - 状态转换策略
domain/policy/AppealUpdateIntentPolicy.java      - 更新意图策略
domain/policy/AppealVisibilityPolicy.java        - 可见性策略
domain/policy/AppealWorkflowDecisionPolicy.java  - 工作流决策策略
```

**依赖**：
- AppealCallerType, AppealEventType
- AppealCallerMetadata, AppealEventMetadata
- AppealRecord 实体（来自 common 模块）

**注意事项**：
- 这些策略类包含核心业务逻辑
- 需要仔细检查与 AppealRecord 实体的引用
- 可能需要调整导入语句

#### 1.3 Domain Services（领域服务）- 3 文件

**优先级**：🟡 中（依赖策略层）

```
domain/AppealRecordDomainService.java        - 核心领域服务
domain/AppealFieldMergeService.java          - 字段合并服务
domain/AppealUpdateMergeCoordinator.java     - 更新合并协调器
domain/idempotency/AppealIdempotencyService.java - 幂等性服务
```

**依赖**：
- 所有 domain/policy 类
- AppealRecord 实体
- 可能依赖 common 模块的 IdempotentRequestExecutor

---

### 2. Infrastructure Layer（基础设施层）- 5 文件

**优先级**：🟡 中（在领域层之后）

#### 2.1 Messaging（消息发布）- 2 文件

```
infrastructure/messaging/AppealRecordEventPublisher.java      - 事件发布器
infrastructure/messaging/TransactionalDomainEventPublisher.java - 事务性事件发布器
```

**依赖**：
- Spring Kafka
- Domain events

#### 2.2 Cache（缓存）- 1 文件

```
infrastructure/cache/AppealRecordCacheService.java - 缓存服务
cache/AppealCachePolicy.java                       - 缓存策略
```

**依赖**：
- Spring Cache
- Redis（可选）

#### 2.3 Search（搜索索引）- 1 文件

```
infrastructure/search/AppealRecordSearchIndexer.java - Elasticsearch 索引器
```

**依赖**：
- Elasticsearch
- AppealRecordSearchProjection

#### 2.4 Transaction（事务管理）- 1 文件

```
infrastructure/transaction/AfterCommitExecutor.java - 事务后执行器
```

**依赖**：
- Spring Transaction

---

### 3. Query & Read Layers（查询和读取层）- 13 文件

**优先级**：🟢 低（可以最后移植）

#### 3.1 Query Layer（查询层）- 6 文件

```
query/AppealRecordQueryService.java          - 查询服务
query/AppealDbFallbackReader.java            - 数据库回退读取器
query/AppealQueryConsistencyValidator.java   - 查询一致性验证器
query/AppealSearchBackfillService.java       - 搜索回填服务
query/AppealSearchQueryAdapter.java          - 搜索查询适配器
query/dto/AppealPageRequest.java             - 分页请求 DTO
```

**依赖**：
- Infrastructure/search
- MyBatis Mapper

#### 3.2 Read Layer（读取模型）- 4 文件

```
read/AppealReadAssembler.java    - 读取组装器
read/AppealReadModel.java        - 读取模型
read/AppealSearchView.java       - 搜索视图
read/AppealWorkflowView.java     - 工作流视图
```

**依赖**：
- Query layer
- Projection layer

#### 3.3 Projection Layer（投影层）- 3 文件

```
projection/AppealRecordProjectionAssembler.java  - 投影组装器
projection/AppealRecordSearchProjection.java     - 搜索投影
projection/AppealRecordView.java                 - 视图模型
```

**依赖**：
- Domain layer
- AppealRecord 实体

---

### 4. Application Layer（应用层）- 2 文件 ⭐ 最后移植

**优先级**：🟢 最低（依赖所有其他层）

```
application/AppealRecordApplicationService.java      - 应用服务（主入口）
application/workflow/AppealWorkflowOrchestrator.java - 工作流编排器
```

**依赖**：
- Domain layer
- Infrastructure layer  
- Query layer
- Read layer

**注意事项**：
- 这是外部调用的主要入口
- 需要确保所有依赖层都已正确移植
- 可能需要创建对应的 Controller

---

## 移植顺序建议

### 阶段 1：核心领域（优先）
1. ✅ Policy metadata & types（5 文件）
2. ✅ Domain policies（10 文件）
3. ✅ Domain services（3 文件）

**检查点**：领域逻辑编译通过

### 阶段 2：基础设施
4. ✅ Infrastructure/transaction（1 文件）
5. ✅ Infrastructure/cache（2 文件）
6. ✅ Infrastructure/messaging（2 文件）
7. ✅ Infrastructure/search（1 文件）

**检查点**：基础设施集成正常

### 阶段 3：查询和读取
8. ✅ Projection layer（3 文件）
9. ✅ Read layer（4 文件）
10. ✅ Query layer（6 文件）

**检查点**：查询功能正常

### 阶段 4：应用编排
11. ✅ Application layer（2 文件）
12. ✅ 创建 Controller（新增）

**检查点**：完整功能可用

---

## 批量移植脚本

### 脚本 1：批量提取文件

```bash
#!/bin/bash
# extract_appeal_files.sh

SOURCE_BASE="finalAssignmentBackend/src/main/java/com/tutict/finalassignmentbackend/appeal"
TARGET_BASE="finalAssignmentCloud/finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/appeal"

# 创建目标目录结构
mkdir -p ${TARGET_BASE}/{domain/policy,domain/idempotency,infrastructure/{cache,messaging,search,transaction},query/dto,read,projection,application/workflow,cache}

# 批量提取 domain/policy 文件
for file in AppealCallerType AppealEventType AppealCallerMetadata AppealEventMetadata \
            AppealBusinessPolicy AppealCallerIntentPolicy AppealEventIntentPolicy \
            AppealFieldMutationPolicy AppealQueryPolicy AppealTransitionPolicy \
            AppealUpdateIntentPolicy AppealVisibilityPolicy AppealWorkflowDecisionPolicy; do
  git show main:${SOURCE_BASE}/domain/policy/${file}.java > /tmp/${file}.java
  sed -i 's/com.tutict.finalassignmentbackend.appeal/com.tutict.finalassignmentcloud.system.appeal/g' /tmp/${file}.java
  sed -i 's/com.tutict.finalassignmentbackend.entity/com.tutict.finalassignmentcloud.entity/g' /tmp/${file}.java
  cp /tmp/${file}.java ${TARGET_BASE}/domain/policy/
done

echo "Domain policies extracted: 14 files"

# 批量提取 domain services
for file in AppealRecordDomainService AppealFieldMergeService AppealUpdateMergeCoordinator; do
  git show main:${SOURCE_BASE}/domain/${file}.java > /tmp/${file}.java
  sed -i 's/com.tutict.finalassignmentbackend/com.tutict.finalassignmentcloud.system/g' /tmp/${file}.java
  cp /tmp/${file}.java ${TARGET_BASE}/domain/
done

git show main:${SOURCE_BASE}/domain/idempotency/AppealIdempotencyService.java > /tmp/AppealIdempotencyService.java
sed -i 's/com.tutict.finalassignmentbackend/com.tutict.finalassignmentcloud.system/g' /tmp/AppealIdempotencyService.java
cp /tmp/AppealIdempotencyService.java ${TARGET_BASE}/domain/idempotency/

echo "Domain services extracted: 4 files"
```

### 脚本 2：批量更新包名

```bash
#!/bin/bash
# update_package_names.sh

TARGET_BASE="finalAssignmentCloud/finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/appeal"

# 递归更新所有 .java 文件的包名
find ${TARGET_BASE} -name "*.java" -type f -exec sed -i \
  -e 's/com.tutict.finalassignmentbackend.appeal/com.tutict.finalassignmentcloud.system.appeal/g' \
  -e 's/com.tutict.finalassignmentbackend.entity/com.tutict.finalassignmentcloud.entity/g' \
  -e 's/com.tutict.finalassignmentbackend.common/com.tutict.finalassignmentcloud.common/g' \
  -e 's/com.tutict.finalassignmentbackend.mapper/com.tutict.finalassignmentcloud.mapper/g' \
  {} \;

echo "Package names updated for all Appeal files"
```

---

## 需要的依赖

### pom.xml（finalassignmentcloud-system）

```xml
<!-- 如果还没有，需要添加 -->
<dependencies>
    <!-- Common 模块 -->
    <dependency>
        <groupId>com.tutict</groupId>
        <artifactId>finalassignmentcloud-common</artifactId>
    </dependency>
    
    <!-- Spring Cache -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-cache</artifactId>
    </dependency>
    
    <!-- Spring Kafka -->
    <dependency>
        <groupId>org.springframework.kafka</groupId>
        <artifactId>spring-kafka</artifactId>
    </dependency>
    
    <!-- Elasticsearch -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-elasticsearch</artifactId>
    </dependency>
    
    <!-- Redis (optional, for cache) -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
</dependencies>
```

---

## 验证清单

### ✅ 阶段 1 验证
- [ ] 所有 policy 类编译通过
- [ ] Domain services 无编译错误
- [ ] 单元测试通过（如果有）

### ✅ 阶段 2 验证
- [ ] 事件发布器可以发送消息
- [ ] 缓存服务正常工作
- [ ] Elasticsearch 索引器连接成功
- [ ] 事务后执行器正常

### ✅ 阶段 3 验证
- [ ] 查询服务可以从数据库读取
- [ ] 搜索查询返回正确结果
- [ ] 读取模型组装正确

### ✅ 阶段 4 验证
- [ ] 应用服务所有方法可调用
- [ ] Controller 端点可访问
- [ ] 完整业务流程测试通过

---

## 常见问题

### Q1: 如果 AppealRecord 实体不存在怎么办？
**A**: 需要先检查 `finalassignmentcloud-common/entity/AppealRecord.java` 是否存在。如果不存在，需要从 main 分支复制。

### Q2: MyBatis Mapper 在哪里？
**A**: Mapper 接口应该在 `finalassignmentcloud-system/mapper/` 包中。如果不存在，需要从 main 分支的 `finalAssignmentBackend/mapper/` 复制对应的 `AppealRecordMapper.java`。

### Q3: 编译错误：找不到某个类
**A**: 检查依赖顺序：
1. 确保 common 模块已编译
2. 确保所有依赖的 policy 类已移植
3. 检查 import 语句的包名是否正确

### Q4: Elasticsearch 连接失败
**A**: 检查 application.yml 中的 Elasticsearch 配置，确保服务已启动。

---

## 预期结果

完成 Phase 2 后，你将拥有：

1. ✅ 完整的 Appeal 领域模型
2. ✅ 事件驱动的申诉流程
3. ✅ 缓存优化的查询性能
4. ✅ Elasticsearch 支持的全文搜索
5. ✅ 事务一致性保证
6. ✅ 完整的 DDD 架构示例

**文件统计**：38 个 Java 文件

**代码行数**：约 3,000-4,000 行

**预计工作时间**：2-3 小时（有脚本辅助）

---

## 快速开始

如果你想立即开始：

```bash
# 1. 进入项目根目录
cd /c/Users/tutic/IdeaProjects/Final-Assignment-spring-cloud

# 2. 创建 Appeal 目录结构
mkdir -p finalAssignmentCloud/finalassignmentcloud-system/src/main/java/com/tutict/finalassignmentcloud/system/appeal/{domain/{policy,idempotency},infrastructure/{cache,messaging,search,transaction},query/dto,read,projection,application/workflow,cache}

# 3. 开始提取文件（从 policy metadata 开始）
git show main:finalAssignmentBackend/src/main/java/com/tutict/finalassignmentbackend/appeal/domain/policy/AppealCallerType.java

# 4. 按照阶段 1-4 的顺序移植
```

---

## 支持

如果遇到问题，参考：
- Phase 1 的成功经验
- `SPRING_CLOUD_SYNC_SUMMARY.md`
- 本指南的"常见问题"部分

祝移植顺利！🚀
