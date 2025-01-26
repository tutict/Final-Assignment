# Final-Assignment
（一个开发中的毕设）

********************************************

这是一个交通违法行为处理管理系统项目，此项目采用Flutter前端与Java后端架构（Quarkus/Spring Boot 3）实现，未来考虑结合Flutter，将此项目开发成鸿蒙应用以支持多端适配。


- **运行代码之前需要确保docker在后台运行。**

## Quarkus

基于Quarkus框架的交通管理系统后端实现，关键依赖特性：
- 🛠 **核心架构**：Vert.x异步驱动 + Quarkus DI容器 + GraalVM原生编译支持
- 🔐 **安全体系**：JWT令牌鉴权 + BCrypt加密 + 细粒度权限控制
- 🚀 **核心功能**：
    - 违法数据管理（MyBatis Plus + MySQL）
    - Kafka实时消息处理（Vert.x集成）
    - 多级缓存策略（Redis + Quarkus Cache）
- 🔧 **性能优化**：
    - GraalVM Native Image构建（启动时间<0.5s / 内存占用<100MB）
    - 响应式消息流（Smallrye Reactive）
    - 阿里云智能服务集成百炼平台（DashScope SDK）
- 📘 **开放能力**：OpenAPI 3.0规范文档自动生成

#### application.properties参考：

``` properties

# Suppress inspection "SpringBootApplicationProperties" for whole file  
%dev.quarkus.http.port=8080  
  
# Database settings  
quarkus.datasource.db-kind=mysql  
quarkus.datasource.jdbc.url=jdbc:mysql://localhost:3306/XXXX?useUnicode=true&characterEncoding=UTF-8&autoReconnect=true&useSSL=false&zeroDateTimeBehavior=convertToNull&serverTimezone=Asia/Shanghai  
quarkus.datasource.jdbc.driver=com.mysql.cj.jdbc.Driver  
quarkus.datasource.username=root  
quarkus.datasource.password=root  
  
# MyBatis Plus settings  
quarkus.mybatis.xmlconfig.enable=false  
quarkus.mybatis.environment=development  
quarkus.mybatis-plus.pagination.enabled=true  
quarkus.mybatis.map-underscore-to-camel-case=true  
  
# JWT settings  
quarkus.smallrye-jwt.enabled=true  
  
# Security settings  
quarkus.security.users.embedded.enabled=true  
quarkus.security.users.embedded.plain-text=true  
quarkus.security.users.embedded.users.user=password  
quarkus.security.users.embedded.users.admin=password  
quarkus.security.users.embedded.roles.user=USER  
quarkus.security.users.embedded.roles.admin=ADMIN  
  
# Cache settings  
quarkus.cache.enabled=true  
quarkus.cache.redis.enabled=true  
quarkus.cache.redis.serializer=jackson # Verify if 'serializer' is the correct key  
quarkus.cache.redis.codec=json # If 'codec' is required instead of 'value-encoder'  
quarkus.cache.redis.default-ttl=10M # Ensure the key is 'default-ttl' not 'default-entry-ttl'  
quarkus.cache.redis.ignore-null-values=true  
quarkus.cache.redis.allow-null-values=false  
  
# Cache configurations for specific services  
quarkus.cache.redis.appealCache.value-type=finalassignmentbackend.service.AppealManagementService  
quarkus.cache.redis.backupCache.value-type=finalassignmentbackend.service.BackupRestoreService  
quarkus.cache.redis.deductionCache.value-type=finalassignmentbackend.service.DeductionInformationService  
quarkus.cache.redis.driverCache.value-type=finalassignmentbackend.service.DriverInformationService  
quarkus.cache.redis.fineCache.value-type=finalassignmentbackend.service.FineInformationService  
quarkus.cache.redis.loginCache.value-type=finalassignmentbackend.service.LoginLogService  
quarkus.cache.redis.offenseCache.value-type=finalassignmentbackend.service.OffenseInformationService  
quarkus.cache.redis.operationCache.value-type=finalassignmentbackend.service.OperationLogService  
quarkus.cache.redis.permissionCache.value-type=finalassignmentbackend.service.PermissionManagementService  
quarkus.cache.redis.roleCache.value-type=finalassignmentbackend.service.RoleManagementService  
quarkus.cache.redis.systemLogCache.value-type=finalassignmentbackend.service.SystemLogsService  
quarkus.cache.redis.systemSettingsCache.value-type=finalassignmentbackend.service.SystemSettingsService  
quarkus.cache.redis.userCache.value-type=finalassignmentbackend.service.UserManagementService  
quarkus.cache.redis.vehicleCache.value-type=finalassignmentbackend.service.VehicleInformationService  
  
# Configure a Caffeine cache named "driverInfoCache"  
quarkus.cache.caffeine."driverInfoCache".expire-after-write=5M  
quarkus.cache.caffeine."driverInfoCache".maximum-size=100  
  
# Logging configurations  
quarkus.log.level=INFO  
quarkus.log.category."io.quarkus".level=INFO  
quarkus.log.category."io.vertx".level=INFO  
  
# Native image build  
quarkus.native.builder-image=true  
  
# JWT Secret Key  
jwt.secret.key=xXXXXXXX=
  
# Network configurations  
network.server.port=8081  
backend.url=http://localhost  
ws.url = ws://localhost:8081  
backend.port=8080  
  
# CORS settings  
quarkus.http.cors=true  
quarkus.http.cors.origins=http://localhost:10086  
quarkus.http.cors.methods=GET,POST,PUT,DELETE,OPTIONS  
quarkus.http.cors.headers=Content-Type,Authorization  
quarkus.http.cors.exposed-headers=Content-Type,Authorization  
quarkus.http.cors.access-control-allow-credentials=true

```

## Spring Boot


**<span style="color:#e74c3c">我将首先集中精力开发Quarkus代码，随后基于Quarkus的实现对Spring Boot代码进行优化。</span>**

#### 技术架构
- 🚀 **核心框架**  
  Spring Boot 3.4 + Java 22
- 🛠 **数据层**  
  MyBatis Plus 3.5.7 + MySQL + Redis 多级缓存

#### 关键特性
- 🔐 **安全体系**  
  JWT 鉴权（双实现方案） + Spring Security 6.3 + BCrypt 加密
- 📡 **实时处理**  
  Kafka 消息队列 + WebSocket 实时推送 + 异步 Vert.x 处理
- ☁️ **云原生支持**  
  Spring Actuator 监控 + Docker 集成 + 阿里云 DashScope AI 服务
- ⚡ **性能优化**  
  Caffeine 本地缓存 + Jedis 连接池

#### 扩展能力
- 📘 OpenAPI 3 规范接口
- 🔌 混合通信模式（HTTP/REST + WebSocket）
- 📊 多数据源支持（关系型 + 缓存 + 消息队列）

#### application.properties参考：
``` properties

spring.application.name=finalAssignmentBackend  
server.port=8080  
spring.datasource.url=jdbc:mysql://localhost:3306/XXXX
spring.datasource.username=root  
spring.datasource.password=root  
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver  
mybatis-plus.mapper-locations=classpath*:/mapper/**/*.xml  
mybatis-plus.type-aliases-package=com.tutict.finalassignmentbackend.entity  
mybatis-plus.configuration.map-underscore-to-camel-case=true  
logging.level.root=INFO  
logging.level.com.example.finalassignmentbackend=DEBUG  
debug=true  
# Kafka  
spring.kafka.bootstrap-servers=localhost:9092  
spring.kafka.consumer.group-id=my-group  
spring.kafka.consumer.auto-offset-reset=earliest  
spring.kafka.consumer.key-deserializer=org.apache.kafka.common.serialization.StringDeserializer  
spring.kafka.consumer.value-deserializer=org.apache.kafka.common.serialization.StringDeserializer  
spring.kafka.producer.key-serializer=org.apache.kafka.common.serialization.StringSerializer  
spring.kafka.producer.value-serializer=org.apache.kafka.common.serialization.StringSerializer  
spring.kafka.producer.acks=1  
#jwt set secret key2  
jwt.secret-key=xXXXXXXXXX=  
#redis settings  
spring.data.redis.host=localhost  
spring.data.redis.port=6379  
# Server Configuration  
#server.port=8081  
# Backend Service Configuration  
backend.url=http://localhost  
backend.port=8081

```

## 八股选猿

- 对八股文的一些练习放在`final_assignment_backend_quarkus/src/test/java/bagu`路径下