# Docker Compose Quick Start Guide

## Overview

This Docker Compose configuration provides a complete infrastructure for the Spring Cloud microservices system.

## What's Included

### Infrastructure Services
- **MySQL 8.0** - Main database (port 3306)
- **Redis 7** - Cache and session store (port 6379)
- **Elasticsearch 8.11** - Search engine (port 9200)
- **Kafka 7.5** - Message queue (port 9092)
- **Zookeeper** - Kafka coordinator (port 2181)
- **Nacos 2.3** - Service discovery & config (port 8848)

### Network
- All services in `finalassignment-network`
- Automatic service discovery via DNS

## Quick Start

### 1. Start Infrastructure Only

```bash
# Start all infrastructure services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f

# Wait for all services to be healthy (~2 minutes)
docker compose ps | grep "healthy"
```

### 2. Initialize Database

```bash
# The database will auto-initialize from ./database/*.sql files
# Check if initialization completed
docker compose exec mysql mysql -uroot -proot123456 -e "SHOW DATABASES;"
```

### 3. Access Services

- **Nacos Console**: http://localhost:8848/nacos (username: nacos, password: nacos)
- **Elasticsearch**: http://localhost:9200
- **MySQL**: localhost:3306 (root/root123456)
- **Redis**: localhost:6379 (password: redis123456)

### 4. Run Microservices

#### Option A: Run with Maven (Recommended for Development)

```bash
# Terminal 1 - Gateway
cd finalAssignmentCloud/finalassignmentcloud-gateway
mvn spring-boot:run

# Terminal 2 - Auth
cd finalAssignmentCloud/finalassignmentcloud-auth
mvn spring-boot:run

# Terminal 3 - User
cd finalAssignmentCloud/finalassignmentcloud-user
mvn spring-boot:run

# Terminal 4 - Traffic
cd finalAssignmentCloud/finalassignmentcloud-traffic
mvn spring-boot:run

# Terminal 5 - Audit
cd finalAssignmentCloud/finalassignmentcloud-audit
mvn spring-boot:run

# Terminal 6 - System
cd finalAssignmentCloud/finalassignmentcloud-system
mvn spring-boot:run
```

#### Option B: Run with Docker (After building JARs)

```bash
# Build JARs
mvn clean package -DskipTests -f finalAssignmentCloud/pom.xml

# Uncomment microservices in docker-compose.yml
# Then start all
docker compose up -d
```

### 5. Verify Services

```bash
# Check Gateway
curl http://localhost:8080/actuator/health

# Check Nacos registrations
curl http://localhost:8848/nacos/v1/ns/instance/list?serviceName=gateway-service
```

### 6. Run k6 Performance Tests

```bash
cd k6-tests
./run-tests.sh
```

## Service Ports

| Service | Port | Purpose |
|---------|------|---------|
| Gateway | 8080 | API Gateway |
| Auth | 8081 | Authentication |
| User | 8082 | User Management |
| Traffic | 8083 | Traffic Violations |
| Audit | 8084 | Audit Logs |
| System | 8085 | System Config |
| MySQL | 3306 | Database |
| Redis | 6379 | Cache |
| Elasticsearch | 9200 | Search |
| Kafka | 9092 | Message Queue |
| Nacos | 8848 | Service Registry |

## Common Commands

### Start/Stop

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose stop

# Stop and remove all
docker compose down

# Stop and remove with volumes (WARNING: deletes data!)
docker compose down -v
```

### Logs

```bash
# View all logs
docker compose logs

# Follow logs
docker compose logs -f

# Specific service logs
docker compose logs -f mysql
docker compose logs -f nacos
```

### Health Checks

```bash
# Check all services status
docker compose ps

# Check specific service
docker compose exec mysql mysqladmin ping -h localhost -uroot -proot123456
docker compose exec redis redis-cli -a redis123456 ping
curl http://localhost:9200/_cluster/health
curl http://localhost:8848/nacos/v1/console/health/readiness
```

### Database Access

```bash
# MySQL CLI
docker compose exec mysql mysql -uroot -proot123456 traffic_management

# Redis CLI
docker compose exec redis redis-cli -a redis123456

# Elasticsearch
curl http://localhost:9200/_cat/indices?v
```

## Troubleshooting

### Services Not Starting

```bash
# Check logs
docker compose logs <service-name>

# Restart service
docker compose restart <service-name>

# Check resources
docker stats
```

### Port Conflicts

```bash
# Check what's using the port
netstat -ano | findstr ":8080"
netstat -ano | findstr ":3306"

# Stop conflicting services or change ports in docker-compose.yml
```

### Database Connection Issues

```bash
# Verify MySQL is ready
docker compose exec mysql mysqladmin ping -h localhost -uroot -proot123456

# Check database exists
docker compose exec mysql mysql -uroot -proot123456 -e "SHOW DATABASES;"

# Re-initialize if needed
docker compose down -v
docker compose up -d
```

### Nacos Registration Issues

```bash
# Check Nacos is ready
curl http://localhost:8848/nacos/v1/console/health/readiness

# View registered services
curl http://localhost:8848/nacos/v1/ns/instance/list?serviceName=gateway-service
```

## Performance Tuning

### For Load Testing

Increase container resources in docker-compose.yml:

```yaml
services:
  mysql:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

### JVM Settings

Add to microservices environment:

```yaml
environment:
  JAVA_OPTS: "-Xms512m -Xmx1g -XX:+UseG1GC"
```

## Clean Up

```bash
# Stop all
docker compose stop

# Remove containers
docker compose down

# Remove volumes (WARNING: deletes all data!)
docker compose down -v

# Remove images
docker compose down --rmi all
```

## Next Steps

1. ✅ Start infrastructure: `docker compose up -d`
2. ⏱️ Wait 2 minutes for services to be healthy
3. ✅ Start microservices (Maven or Docker)
4. ✅ Run k6 tests: `cd k6-tests && ./run-tests.sh`
5. 📊 Analyze results

## Support

For issues:
1. Check logs: `docker compose logs -f`
2. Verify health: `docker compose ps`
3. Check connectivity: `docker compose exec <service> sh`
4. Review application logs in each microservice
