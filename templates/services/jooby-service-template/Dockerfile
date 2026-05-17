FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app
COPY gradle/ gradle/
COPY gradlew .
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY src/ src/

RUN ./gradlew build -x test

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

RUN addgroup -g 1000 appgroup && adduser -u 1000 -G appgroup -s /bin/sh -D appuser

COPY --from=builder /app/build/libs/ /app/

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -Xms256m"
ENV APP_NAME="__SERVICE__-service"

HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/__SERVICE__-service.jar"]
