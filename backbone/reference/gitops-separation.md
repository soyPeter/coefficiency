# GitOps Separation Strategy

## Current State

Single-template approach: `new-service.sh` generates everything in one pass into a single service directory.

```
my-service/
├── src/main/java/...     # Application code
├── src/main/resources/    # Configuration
├── build.gradle.kts       # Build config
└── Dockerfile            # Container definition
```

## Target State (Future)

Dual-repo approach: Source code repo + GitOps config repo

```
my-service/                      # Source code repository
├── src/
├── build.gradle.kts
└── ...

my-service-config/               # GitOps repository
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
├── argocd/
│   └── app.yaml
└── ci/
    └── github-actions.yaml
```

## Why Separate?

| Benefit | Description |
|---------|-------------|
| **Decoupled deployments** | Infrastructure changes don't require source code changes |
| **GitOps audit trail** | Every deployment is a git commit |
| **Team separation** | Platform team manages infra, app team manages code |
| **Atomic updates** | Config changes can be rolled back independently |
| **Secret management** | Config repo can be private, source repo public |

## Migration Path

### Phase 1: Preparation (Current)
- [x] Create `skeleton-fragments/` with reusable K8s/CI configs
- [x] Add `template.yaml` metadata to service templates
- [x] Document parameter schema

### Phase 2: Optional GitOps Flag
```
new-service.sh --service customer --gitops
```
This would generate:
- `customer/` - Source code
- `customer-config/` - GitOps manifests

### Phase 3: Full Backstage Integration
Convert `template.yaml` to full Backstage template with:
```yaml
steps:
  - id: sourceCode
    action: fetch:template
    input:
      url: ./skeleton
  
  - id: gitOps
    action: fetch:template
    input:
      url: ../../skeleton-fragments/k8s
      values:
        appName: ${{ parameters.serviceName }}
  
  - id: publish
    action: publish:github
    # Creates two repos
```

## Skeleton Fragments

Located in `backbone/templates/skeleton-fragments/`:

```
skeleton-fragments/
├── k8s/           # Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
├── ci/            # CI/CD pipelines
│   └── github-actions.yaml
└── argocd/        # ArgoCD configuration
    └── app.yaml
```

## Parameter Reference

These parameters are used in skeleton fragments:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `appName` | Service name | (required) |
| `namespace` | K8s namespace | `default` |
| `version` | Image version | `latest` |
| `containerPort` | Container port | `8080` |
| `servicePort` | Service port | `80` |
| `replicas` | Pod replicas | `3` |
| `imageRegistry` | Container registry | `image-registry.openshift-image-registry.svc:5000` |
| `host` | Ingress host | `api.example.com` |
| `tlsEnabled` | TLS enabled | `true` |
| `gitRepoUrl` | Git repository URL | (required) |
| `branch` | Git branch | `main` |
| `argocdProject` | ArgoCD project | `default` |

## Rollback Procedures

### Source Code Rollback
```bash
git revert <commit>
git push
```

### Infrastructure Rollback
```bash
git revert <commit>  # in my-service-config repo
git push
argocd app sync my-service --force-rollback
```

## Decisions

See `backbone/decisions/` for architectural decisions related to GitOps:
- [[decisions/YYYYMMDD-gitops-strategy.md]]
