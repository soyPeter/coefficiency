<!-- FRAMEWORK: CROSSPLANE -->
---
framework: crossplane
name: crossplane-patterns
description: Crossplane infrastructure provisioning patterns for cloud-native Kubernetes applications. Use when adding cloud resource claims, creating Compositions, or managing infrastructure-as-code with Crossplane.
origin: agentic-backbone
version: "1.0"
---

# Crossplane Patterns (Production)

Patterns for defining and managing cloud infrastructure as Kubernetes-native resources using Crossplane.

## When to Use

- Adding infrastructure claims (Database, Storage, Cache) to a generated project
- Creating or updating CompositeResourceDefinitions (XRDs)
- Writing Compositions that map generic claims to cloud-specific resources
- Extending the infrastructure catalog with new resource types
- Managing infrastructure-as-code with Crossplane + GitOps

## Core Concepts

### 1. CompositeResourceDefinition (XRD)
The **interface** — defines the schema of a claimable resource.
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: CompositeResourceDefinition
metadata:
  name: xpostgresinstances.crossplane.backbone.io
spec:
  group: crossplane.backbone.io
  names:
    kind: XPostgresInstance
    plural: xpostgresinstances
  claimNames:
    kind: PostgresInstance
    plural: postgresinstances
  connectionSecretStyle: Secret
  keys:
    - username
    - password
    - endpoint
    - port
    - database
```

### 2. Composition
The **implementation** — maps an XRD to actual cloud resources with patch-and-transform.
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  labels:
    provider: aws
    cloud: production
spec:
  compositeTypeRef:
    apiVersion: crossplane.backbone.io/v1alpha1
    kind: XPostgresInstance
  environmentConfigs:
    - name: aws-config
      kind: EnvironmentConfig
  patchSets:
    - name: tags
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: metadata.labels[app]
          toFieldPath: spec.forProvider.tags[app]
  resources:
    - name: rds
      base:
        apiVersion: database.aws.upbound.io/v1beta1
        kind: Instance
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.storageGB
          toFieldPath: spec.forProvider.allocatedStorage
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.tier
          toFieldPath: spec.forProvider.instanceClass
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.engineVersion
          toFieldPath: spec.forProvider.engineVersion
        - type: FromCompositeFieldPath
          fromFieldPath: metadata.labels[environment]
          toFieldPath: spec.forProvider.multiAz
          transforms:
            - type: string
              string:
                fmt: "%v"
                parse: "%s"
        - type: FromCompositeFieldPath
          fromFieldPath: metadata.name
          toFieldPath: spec.forProvider.dbName
      connectionDetails:
        - name: username
          fromConnectionSecretKey: username
        - name: password
          fromConnectionSecretKey: password
        - name: endpoint
          fromConnectionSecretKey: endpoint
        - name: port
          fromConnectionSecretKey: port
        - name: database
          fromConnectionSecretKey: database
      readinessChecks:
        - type: NonEmpty
          fieldPath: status.atProvider.endpoint
```

### 3. Claim
The **request** — a namespaced resource that a developer adds to their project.
```yaml
apiVersion: postgresinstance.crossplane.backbone.io/v1alpha1
kind: PostgresInstance
metadata:
  name: my-app-db
  labels:
    environment: production
spec:
  parameters:
    storageGB: 50
    tier: db.t3.medium
    engineVersion: "15.4"
  writeConnectionSecretToRef:
    name: my-app-db-credentials
  compositionRef:
    name: aws-postgres-production
```

### 4. EnvironmentConfig
Provider-agnostic configuration that compositions patch from.
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: EnvironmentConfig
metadata:
  name: aws-config
data:
  region: us-east-1
  vpcId: vpc-0abc123
  subnetIds: "subnet-1,subnet-2,subnet-3"
  securityGroupIds: "sg-abc123"
```

## Standard Infrastructure Claims

### PostgreSQL Instance
```yaml
apiVersion: postgresinstance.crossplane.backbone.io/v1alpha1
kind: PostgresInstance
metadata:
  name: my-app-db
spec:
  parameters:
    storageGB: 20
    engineVersion: "15"
    tier: db.t3.micro
  writeConnectionSecretToRef:
    name: my-app-db-credentials
```

### Object Storage Bucket
```yaml
apiVersion: objectstoragebucket.crossplane.backbone.io/v1alpha1
kind: ObjectStorageBucket
metadata:
  name: my-app-storage
spec:
  parameters:
    region: us-east-1
    publiclyAccessible: false
    acl: private
  writeConnectionSecretToRef:
    name: my-app-storage-credentials
```

### Redis Cache
```yaml
apiVersion: rediscluster.crossplane.backbone.io/v1alpha1
kind: RedisCluster
metadata:
  name: my-app-cache
spec:
  parameters:
    numCacheNodes: 2
    engineVersion: "7.0"
    nodeType: cache.t3.micro
  writeConnectionSecretToRef:
    name: my-app-cache-credentials
```

## Patch and Transform Patterns

### String Transformation
```yaml
patches:
  - type: FromCompositeFieldPath
    fromFieldPath: spec.parameters.tier
    toFieldPath: spec.forProvider.instanceClass
    transforms:
      - type: string
        string:
          fmt: "db.%s"
          parse: "db.%s"
```

### Convert Boolean to String
```yaml
patches:
  - type: FromCompositeFieldPath
    fromFieldPath: spec.parameters.multiAz
    toFieldPath: spec.forProvider.multiAz
    transforms:
      - type: convert
        convert:
          format: boolean
```

### Combine Multiple Fields
```yaml
patches:
  - type: CombineFromComposite
    combine:
      variables:
        - fromFieldPath: metadata.labels[environment]
        - fromFieldPath: spec.parameters.engine
      toFieldPath: spec.forProvider.tagSpecifications[0].tags[0].key
    patches:
      - toFieldPath: spec.forProvider.tagSpecifications[0].tags[0].value
        type: CombineFromComposite
        combine:
          variables:
            - fromFieldPath: metadata.labels[environment]
            - fromFieldPath: spec.parameters.engine
          toFieldPath: spec.forProvider.tagSpecifications[0].tags[0].value
```

## Connection Secrets

### App Consumption Pattern
```yaml
# Deployment references the secret
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: my-app-db-credentials
        key: username  # transform: "postgres://$(username):$(password)@$(endpoint):$(port)/$(database)"
```

### Kubernetes Secret from Connection Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-db-url
  annotations:
    crossplane.io/claim-name: my-app-db
type: Opaque
stringData:
  url: "postgres://$(username):$(password)@$(endpoint):$(port)/$(database)"
```

## Provider-Specific Compositions

### AWS RDS PostgreSQL
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: aws-postgres-production
  labels:
    provider: aws
    cloud: production
spec:
  compositeTypeRef:
    apiVersion: crossplane.backbone.io/v1alpha1
    kind: XPostgresInstance
  resources:
    - name: rds
      base:
        apiVersion: database.aws.upbound.io/v1beta1
        kind: Instance
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.storageGB
          toFieldPath: spec.forProvider.allocatedStorage
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.tier
          toFieldPath: spec.forProvider.instanceClass
      connectionDetails:
        - fromConnectionSecretKey: username
        - fromConnectionSecretKey: password
        - fromConnectionSecretKey: endpoint
        - fromConnectionSecretKey: port
        - fromConnectionSecretKey: database
      readinessChecks:
        - type: NonEmpty
          fieldPath: status.atProvider.endpoint
```

### Azure Database for PostgreSQL
```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: azure-postgres-production
  labels:
    provider: azure
    cloud: production
spec:
  compositeTypeRef:
    apiVersion: crossplane.backbone.io/v1alpha1
    kind: XPostgresInstance
  resources:
    - name: postgres
      base:
        apiVersion: database.azure.upbound.io/v1beta1
        kind: PostgreSQLServer
      patches:
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.storageGB
          toFieldPath: spec.forProvider.storageMB
          transform:
            type: math
            math:
              multiply: 1024
        - type: FromCompositeFieldPath
          fromFieldPath: spec.parameters.tier
          toFieldPath: spec.forProvider.sku
      connectionDetails:
        - fromConnectionSecretKey: username
        - fromConnectionSecretKey: password
        - fromConnectionSecretKey: endpoint
        - fromConnectionSecretKey: port
        - fromConnectionSecretKey: database
```

## Readiness and Health Checks

### Wait for Endpoint
```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: status.atProvider.endpoint
```

### Wait for All IPs
```yaml
readinessChecks:
  - type: NonEmpty
    fieldPath: status.atProvider.address
```

### Custom Health Check
```yaml
readinessChecks:
  - type: Condition
    status:
      conditionType: Ready
      status: "True"
  - type: Observe
    strategy: addon
    patchSet: network
```

## Adding a New Resource Type

1. **Define the XRD** in `backbone/artifacts/skeleton-fragments/crossplane/engine/`
2. **Create a Composition** for each cloud provider (AWS, Azure, GCP)
3. **Create a claim template** in `backbone/artifacts/skeleton-fragments/crossplane/claims/`
4. **Update the generator** (`init-project.sh`) to support `--with-<resource>` flag
5. **Update this skill** with the new resource pattern

## Generator Integration

When a project requests infrastructure, the generator injects claims from `backbone/artifacts/skeleton-fragments/crossplane/claims/` into the project's `k8s/claims/` directory. The Kustomize overlay at `k8s/kustomization.yaml` references `./claims` to include them in the GitOps pipeline.

## Dependency Ordering

Infrastructure claims must be **ready before the application deploys**. This is handled by:
1. **Kustomize ordering**: Claims in `k8s/claims/` are applied before app resources
2. **ArgoCD Sync Waves**: Use `annotations.argocd.argoproj.io/sync-wave` to control order
3. **Crossplane Readiness**: Use `crossplane.io/claim-name` annotations to track dependency resolution

## Troubleshooting

### Claim Pending
```bash
# Check composite resource status
kubectl get xpostgresinstance
kubectl describe xpostgresinstance my-app-db

# Check composition errors
kubectl get composition aws-postgres-production -o yaml
```

### Resource Not Ready
```bash
# Check Crossplane provider pods
kubectl get pods -n crossplane-system

# Check provider config
kubectl get providerconfig

# View managed resource
kubectl get managed | grep postgres
```

### Connection Secret Missing
```bash
# Check secret exists
kubectl get secret my-app-db-credentials

# Verify claim references it
kubectl get postgresinstance my-app-db -o yaml | grep writeConnectionSecretToRef
```