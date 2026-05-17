<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: devops-patterns
description: DevOps practices covering CI/CD pipelines, Infrastructure as Code, monitoring, GitOps, and platform engineering. Use when setting up deployment automation, building IaC templates, or establishing observability.
---

# DevOps Patterns Skill

Production-grade DevOps patterns covering CI/CD pipelines, Infrastructure as Code, monitoring, and platform engineering.

## When to Use

- Setting up CI/CD pipelines
- Building Infrastructure as Code templates
- Establishing monitoring and observability
- Implementing GitOps workflows
- Creating platform engineering self-service

## Excellence Checklist

- [ ] Infrastructure automation 100% achieved
- [ ] Deployment automation 100% implemented
- [ ] Test automation > 80% coverage
- [ ] Mean time to production < 1 day
- [ ] Service availability > 99.9%
- [ ] Security scanning automated
- [ ] Documentation as code
- [ ] Automated rollback procedures

## CI/CD Pipeline Patterns

### GitHub Actions Production Pipeline
```yaml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up JDK 21
      uses: actions/setup-java@v4
      with:
        java-version: '21'
        distribution: 'temurin'
        
    - name: Build with Gradle
      run: ./gradlew build -x test
      
    - name: Run tests
      run: ./gradlew test
      
    - name: Security scan
      run: ./gradlew dependencyCheckAnalyze
      
    - name: Build image
      run: |
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest .
        
    - name: Push image
      run: |
        echo ${{ secrets.GITHUB_TOKEN }} | docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production
    steps:
    - name: Deploy to Kubernetes
      run: |
        kubectl set image deployment/api \
          api=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        kubectl rollout status deployment/api --timeout=5m
```

### ArgoCD GitOps Setup
```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api-service
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/org/k8s-config
    targetRevision: HEAD
    path: environments/production/api-service
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Infrastructure as Code

### Terraform Module Pattern
```hcl
# modules/ec2-instance/main.tf
variable "name" {}
variable "ami" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_groups" {}

resource "aws_instance" "this" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = var.security_groups
  
  tags = {
    Name = var.name
    ManagedBy = "terraform"
  }
}

# modules/ec2-instance/outputs.tf
output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

# environments/production/main.tf
module "api_server" {
  source = "../../modules/ec2-instance"
  
  name           = "api-server"
  ami            = var.api_ami
  instance_type  = "t3.medium"
  subnet_id      = module.vpc.private_subnets[0]
  security_groups = [module.security_groups.api]
}
```

### Kubernetes IaC (Terraform)
```hcl
# EKS cluster
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version
  
  vpc_config {
    subnet_ids = var.subnet_ids
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.nodes.arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.instance_types
  
  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }
}
```

## Monitoring and Observability

### SLI/SLO Definition
```yaml
# slo.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceLevelObjective
metadata:
  name: api-availability
spec:
  service: api-service
  sli:
    latency:
      query: |
        histogram_quantile(0.99,
          sum(rate(http_request_duration_seconds_bucket{service="api"}[5m])) by (le)
        )
  objectives:
    - displayName: API Availability
      target: 99.9
      window: 30d
    - displayName: API Latency P99
      target: 99.0
      window: 30d
      targetLatency: "500ms"
```

### Prometheus Alert Rules
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: api-alerts
spec:
  groups:
  - name: api-service
    rules:
    - alert: HighErrorRate
      expr: |
        sum(rate(http_requests_total{service="api",status=~"5.."}[5m])) 
        / 
        sum(rate(http_requests_total{service="api"}[5m])) > 0.01
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate on API service"
        runbook_url: "https://wiki/runbooks/high-error-rate"
        
    - alert: HighLatency
      expr: |
        histogram_quantile(0.99,
          sum(rate(http_request_duration_seconds_bucket{service="api"}[5m])) by (le)
        ) > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High latency on API service"
```

## Platform Engineering

### Developer Self-Service Portal
```yaml
# developer-portal-service-catalog.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: api-service
  annotations:
    github.com/project-slug: org/api-service
spec:
  type: service
  lifecycle: production
  owner: platform-team
  providesApis:
    - api-service-api
---
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: api-service-api
spec:
  type: openapi
  lifecycle: production
  owner: platform-team
  definition:
    $ref: ./openapi.yaml
```

### Golden Path Template
```bash
# create-service.sh
#!/bin/bash
SERVICE_NAME=$1
TEMPLATE_REPO="git@github.com:org/service-template.git"

# Clone template
git clone $TEMPLATE_REPO $SERVICE_NAME
cd $SERVICE_NAME

# Update service name
find . -type f -exec sed -i "s/SERVICE_NAME/$SERVICE_NAME/g" {} \;

# Initialize
git init
git add .
git commit -m "Initial commit from template"
```

## Incident Response

### Incident Response Runbook
```markdown
# Incident Response Runbook

## Severity Levels
- P1: Production down, all users affected
- P2: Major feature broken, >50% users affected
- P3: Minor feature broken, <50% users affected
- P4: Cosmetic issues, no user impact

## Response Steps
1. Acknowledge incident in PagerDuty
2. Create incident Slack channel: #inc-YYYY-MM-DD-name
3. Assign incident commander
4. Begin logging timeline
5. Diagnose root cause
6. Implement fix or rollback
7. Verify resolution
8. Schedule postmortem

## Rollback Procedure
```bash
# Quick rollback to previous version
kubectl rollout undo deployment/api-service

# Verify rollback
kubectl rollout status deployment/api-service
```
```

## Cost Optimization

### AWS Cost Dashboard Query
```sql
SELECT 
  line_item_usage_start_date,
  product_instance_type,
  SUM(line_item_usage_amount) as usage,
  SUM(line_item_unblended_cost) as cost
FROM 
  aws_cost_and_usage
WHERE 
  line_item_product_code = 'AmazonEC2'
  AND line_item_usage_start_date >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1' month)
GROUP BY
  1, 2
ORDER BY
  4 DESC
LIMIT 20;
```
