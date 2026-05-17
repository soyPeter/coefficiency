<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: docker-patterns
description: Docker containerization patterns for production - multi-stage builds, image optimization, security hardening, and supply chain security. Use when writing Dockerfiles, optimizing image sizes, hardening containers, or setting up Docker Compose for production.
---

# Docker Patterns Skill

Production-grade Docker containerization patterns covering build optimization, security hardening, and supply chain integrity.

## When to Use

- Writing or optimizing Dockerfiles
- Reducing image sizes (< 100MB target)
- Hardening container security
- Setting up multi-stage builds
- Configuring Docker Compose for production
- Implementing image signing and provenance

## Excellence Checklist

- [ ] Production images < 100MB where applicable
- [ ] Build time < 5 minutes with optimized caching
- [ ] Zero critical/high vulnerabilities detected
- [ ] 100% multi-stage build adoption
- [ ] Image attestations and provenance enabled
- [ ] CIS Docker Benchmark compliance > 90%
- [ ] Non-root user execution
- [ ] Healthcheck implemented

## Multi-Stage Build Patterns

### Java/Gradle Multi-Stage
```dockerfile
# Build stage
FROM gradle:8.5-jdk21 AS builder
WORKDIR /app
COPY . .
RUN gradle build -x test

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
RUN addgroup -S appuser && adduser -S appuser -G appuser
USER appuser
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Node.js Multi-Stage
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

### Go Multi-Stage
```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o app

# Runtime stage
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/app /app
EXPOSE 8080
ENTRYPOINT ["/app"]
```

## Image Optimization

### Layer Caching Strategy
```dockerfile
# Order layers from least to most frequently changing
FROM alpine:3.19

# Dependencies change rarely
COPY go.mod go.sum ./
RUN go mod download

# Source code changes frequently
COPY . .

# Build at the end
RUN go build -o app
```

### .dockerignore
```
.git
.gitignore
*.md
docs/
tests/
*.test.go
*.spec.js
node_modules/
vendor/
.env*
```

### Minimal Base Images
```dockerfile
# Distroless (preferred for production)
FROM gcr.io/distroless/static-debian12

# Alpine (smaller but more packages)
FROM alpine:3.19

# Scratch (smallest, no shell)
FROM scratch
```

## Container Security

### Non-Root Execution
```dockerfile
RUN addgroup -S appuser && adduser -S appuser -G appuser
USER appuser
```

### Read-Only Filesystem
```dockerfile
USER root
RUN chmod 440 /etc/passwd
USER appuser
```

### Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10000
  runAsGroup: 10000
  fsGroup: 10000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
```

## Supply Chain Security

### BuildKit Secrets (Build Time)
```dockerfile
# syntax=docker/dockerfile:1
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) && \
    echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc && \
    npm ci
```

### SBOM Generation
```bash
# Generate SBOM with syft
syft . -o spdx-json > sbom.spdx.json

# Sign with cosign
cosign sign --yes user/app:latest
```

### Image Signing
```bash
# Sign image
cosign sign --yes user/app:latest

# Verify image
cosign verify --certificate-identity=user/app:latest user/app:latest
```

## Docker Compose Production Patterns

### Production Compose
```yaml
version: '3.9'

services:
  app:
    build: .
    image: user/app:latest
    restart: unless-stopped
    read_only: true
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### Resource Constraints
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

## BuildKit Optimization

### Remote Build Cache
```bash
# Enable buildkit cache
export DOCKER_BUILDKIT=1

# Use registry cache
docker buildx build --push \
  --cache-from type=registry,ref=user/app:buildcache \
  --cache-to type=registry,ref=user/app:buildcache,mode=max \
  -t user/app:latest .
```

### Multi-Platform Builds
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --push \
  -t user/app:latest .
```

## Registry Management

### Image Tagging Strategy
```bash
# Latest only for stable releases
docker tag app:latest user/app:1.0.0
docker tag app:latest user/app:1.0.1

# SHA tags for immutability
docker tag app:latest user/app:sha-abc123

# Latest for bleeding edge
docker tag app:latest user/app:edge
```

## Troubleshooting

### Debug Container
```bash
# Run debug container
docker run --rm -it --privileged user/app:debug sh

# Copy files from running container
docker cp container:/app/logs ./logs
```

### Layer Analysis
```bash
# Show image layers
docker history user/app:latest

# Analyze build cache
docker buildx du
```
