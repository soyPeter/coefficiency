<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: security-devsecops
description: DevSecOps practices for shifting security left - container security, secrets management, compliance automation, and vulnerability management. Use when implementing security automation, setting up vault, or building compliance pipelines.
---

# Security DevSecOps Skill

Infrastructure and DevSecOps security patterns covering container security, secrets management, compliance automation, and vulnerability management.

## When to Use

- Implementing shift-left security
- Setting up secrets management (Vault)
- Building compliance automation
- Configuring container/K8s security
- Implementing zero-trust architecture
- Vulnerability management

## Excellence Checklist

- [ ] CIS benchmarks compliance verified
- [ ] Zero critical vulnerabilities in production
- [ ] Security scanning in CI/CD pipeline
- [ ] Secrets management automated
- [ ] RBAC properly implemented
- [ ] Network segmentation enforced
- [ ] Incident response plan tested
- [ ] Compliance evidence automated

## Secrets Management

### HashiCorp Vault - Kubernetes
```yaml
# vault-external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: kubernetes
          role: "app-role"
---
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: api-secrets
    creationPolicy: Owner
  data:
  - secretKey: DATABASE_PASSWORD
    remoteRef:
      key: production/api-service
      property: db-password
  - secretKey: API_KEY
    remoteRef:
      key: production/api-service
      property: api-key
```

### Vault Dynamic Secrets
```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432" \
  allowed_roles="app-role"

# Create role
vault write database/roles/app-role \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"
```

## Container Security

### Trivy Image Scanning in CI
```yaml
# github-actions-scan.yaml
- name: Run Trivy vulnerability scanner
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1' # Fail on critical vulnerabilities

- name: Upload Trivy results to Security tab
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

### OPA Policy Enforcement
```rego
# container-image-allowed.rego
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not startswith(container.image, "ghcr.io/org/")
  msg := sprintf("Container image '%v' not from approved registry", [container.image])
}

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  container.securityContext.runAsRoot
  msg := "Container must not run as root"
}

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not container.securityContext.readOnlyRootFilesystem
  msg := "Container must use read-only root filesystem"
}
```

## Zero Trust Architecture

### mTLS with Istio
```yaml
# strict-mtls.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-authz
  namespace: production
spec:
  selector:
    matchLabels:
      app: api-service
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/frontend"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/backend"]
    to:
    - operation:
        methods: ["*"]
        paths: ["/api/*"]
```

### Network Policies (Default Deny)
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: ""
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

## Compliance Automation

### Open Policy Agent - CIS Compliance
```rego
# cis-k8s.rego
package kubernetes.cis

deny[msg] {
  input.request.kind.kind == "Pod"
  not input.request.object.spec.securityContext.runAsNonRoot
  msg := "Pod must set runAsNonRoot to true"
}

deny[msg] {
  input.request.kind.kind == "Pod"
  input.request.object.spec.securityContext.runAsUser == 0
  msg := "Pod must not run as root (runAsUser must be > 0)"
}

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  container.securityContext.privileged
  msg := "Container must not run in privileged mode"
}

deny[msg] {
  input.request.kind.kind == "Pod"
  container := input.request.object.spec.containers[_]
  not container.securityContext.capabilities.drop[_] == "ALL"
  msg := "Container must drop ALL capabilities"
}
```

### Policy as Code (Kyverno)
```yaml
# require-labels.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-labels
spec:
  validationFailureAction: Enforce
  rules:
  - name: require-production-label
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Label 'environment' is required for production pods"
      pattern:
        metadata:
          labels:
            environment: "production"
```

## Vulnerability Management

### Dependabot Configuration
```yaml
# .github/dependabot.yml
version: 2
updates:
- package-ecosystem: "gradle"
  directory: "/"
  schedule:
    interval: "weekly"
  open-pull-requests-limit: 10
  reviewers:
    - "@org/security-team"
  labels:
    - "dependencies"
    - "security"
  groups:
    production-dependencies:
      dependency-type: "production"
    development-dependencies:
      dependency-type: "development"
```

### Trivy Operator Setup
```yaml
# trivy-standalone-exporter
apiVersion:apps/v1
kind: Deployment
metadata:
  name: trivy-operator
  namespace: security
spec:
  replicas: 1
  selector:
    matchLabels:
      app: trivy-operator
  template:
    metadata:
      labels:
        app: trivy-operator
    spec:
      serviceAccountName: trivy-operator
      containers:
      - name: trivy
        image: aquasec/trivy:0.50.0
        args:
          - "--standalone"
          - "--db-repository"
          - "ghcr.io/aquasecurity/trivy-db"
        ports:
        - name: metrics
          containerPort: 9090
```

## Cloud Security

### AWS Security Hub Integration
```yaml
# aws-security-hub.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: production
  version: "1.29"
  region: us-east-1
addons:
- name: aws-security-hub
  version: latest
  configuration:
    enable: true
    securities:
      - security-standard: CIS
      - security-standard: PCI
```

### IAM Role for Service Account
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-service
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/api-service-role
---
# trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub": "system:serviceaccount:production:api-service"
        }
      }
    }
  ]
}
```

## Incident Response

### Security Incident Response
```bash
#!/bin/bash
# incident-response.sh

INCIDENT_ID=$1
SEVERITY=$2

# Create incident channel
slack_channel="#inc-$(date +%Y%m%d)-$INCIDENT_ID"

/echo "Incident Response for $INCIDENT_ID (Severity: $SEVERITY)"

# 1. Containment
echo "[1/5] Containing the threat..."
# Block malicious IP
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol all \
  --cidr $MALICIOUS_IP/32

# 2. Investigation
echo "[2/5] Investigating..."
# Get CloudTrail logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=$AFFECTED_RESOURCE \
  --start-time $(date -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)

# 3. Eradication
echo "[3/5] Eradicating..."
# Rotate compromised credentials
aws iam create-access-key --user-name $AFFECTED_USER
aws iam delete-access-key --user-name $AFFECTED_USER --access-key-id $OLD_KEY

# 4. Recovery
echo "[4/5] Recovering..."
# Restore from backup
./restore-from-backup.sh --snapshot $LATEST_SNAPSHOT

# 5. Post-incident
echo "[5/5] Post-incident actions..."
echo "Schedule postmortem within 48 hours"
echo "Update runbooks if needed"
```
