# Multi-stage build for the Spring Boot main backend (Java 25).
# Build:  docker build -f finalAssignmentBackend/Dockerfile -t final-assignment-spring:latest .
# Run:    see compose.app.yml — the app reads SPRING_* env vars for the DB/Redis addresses.

FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /workspace
COPY pom.xml .
# Dependencies layer first so source edits don't invalidate the dependency cache.
RUN mvn -q dependency:go-offline -DskipTests
COPY src ./src
RUN mvn -q package -DskipTests

FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /workspace/target/*.jar app.jar
EXPOSE 8080
# Heapsize is container-aware; JAVA_OPTS lets compose override JVM flags.
ENV JAVA_OPTS=""
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
