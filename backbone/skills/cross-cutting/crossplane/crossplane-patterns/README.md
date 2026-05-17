# Crossplane Patterns Skill

> Infrastructure provisioning patterns for cloud-native Kubernetes applications using Crossplane

## What It Does

Defines and manages cloud infrastructure as Kubernetes-native resources:
- CompositeResourceDefinitions (XRD) — the interface
- Compositions — the implementation per cloud provider
- Claims — developer-facing infrastructure requests

## When to Use

- Adding infrastructure claims (Database, Storage, Cache) to a generated project
- Creating or updating CompositeResourceDefinitions (XRDs)
- Writing Compositions that map generic claims to cloud-specific resources
- Extending the infrastructure catalog with new resource types
- Managing infrastructure-as-code with Crossplane + GitOps

## Key Concepts

### Resource Hierarchy

```
XRD (Interface) → Composition (Implementation) → Claim (Request)
```

### Core Patterns

| Pattern | Purpose |
|---------|---------|
| XRD | Defines schema of claimable resource |
| Composition | Maps XRD to AWS/Azure/GCP resources |
| Claim | Developer-facing namespaced resource |
| Patch & Transform | Modify resources at composition time |
| Connection Secret | Store credentials for app consumption |
| Environment Config | Provider-agnostic configuration |

## When NOT to Use

- Simple Helm charts suffice (use Helm instead)
- No cloud resources needed (use K8s primitives)
- State not needed (use K8s ConfigMaps)

## Related Skills

- `kubernetes` — K8s resource patterns
- `gitops` — ArgoCD sync and GitOps workflows
- `observability` — Infrastructure monitoring

## References

- [Crossplane Docs](https://docs.crossplane.io/)
- [Upbound Provider AWS](https://marketplace.upbound.io/providers/upbound/provider-aws)
- [Crossplane Composition Patterns](https://docs.crossplane.io/v1.14/concepts/compositions/)