<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: kubernetes-patterns
description: Kubernetes cluster design, deployment patterns, security hardening, and operations for production environments. Use when designing K8s clusters, deploying workloads, configuring RBAC, setting up network policies, or implementing GitOps workflows.
---

# Kubernetes Patterns Skill

Production-grade Kubernetes patterns covering cluster architecture, workload orchestration, security hardening, and GitOps workflows.

## When to Use

- Designing Kubernetes cluster architecture
- Deploying applications to Kubernetes
- Configuring RBAC and security policies
- Setting up networking and ingress
- Implementing GitOps workflows
- Troubleshooting K8s issues

## Excellence Checklist

- [ ] CIS Kubernetes Benchmark compliance verified
- [ ] Cluster uptime 99.95% achieved
- [ ] Pod startup time < 30s optimized
- [ ] Resource utilization > 70% maintained
- [ ] Security policies enforced
- [ ] RBAC properly configured
- [ ] Network policies implemented
- [ ] Disaster recovery tested

## Cluster Architecture

### Production Cluster Design
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    env: production
    team: platform
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
spec:
  hard:
    requests.cpu: "40"
    requests.memory: 128Gi
    limits.cpu: "80"
    limits.memory: 256Gi
    pods: "100"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
spec:
  limits:
  - type: Container
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    max:
      cpu: "4"
      memory: 4Gi
```

### Multi-Node Pool Configuration
```yaml
apiVersion: v1
kind: NodePool
metadata:
  name: general-purpose
spec:
  minNodes: 3
  maxNodes: 10
  instanceType: n2-standard-4
  labels:
    workload-type: general
---
apiVersion: v1
kind: NodePool
metadata:
  name: memory-optimized
spec:
  minNodes: 1
  maxNodes: 5
  instanceType: n2-standard-8
  labels:
    workload-type: memory-intensive
  taints:
    - key: workload
      value: memory-intensive
      effect: NoSchedule
```

## Workload Deployment

### Production Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
        version: v1
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 10000
        fsGroup: 10000
      containers:
      - name: api
        image: user/api:v1.2.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
```

### PodDisruptionBudget
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-service-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: api-service
```

### HorizontalPodAutoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-service
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## Security Hardening

### Pod Security Standards
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-developer
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-developer-binding
  namespace: production
subjects:
- kind: Group
  name: app-developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: app-developer
  apiGroup: rbac.authorization.k8s.io
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          kube-system: coredns
    ports:
    - protocol: UDP
      port: 53
```

## GitOps with ArgoCD

### Application Definition
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api-service
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/org/k8s-config
    targetRevision: main
    path: apps/api-service/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

### Helm Chart Structure
```
api-service/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── hpa.yaml
    ├── pdb.yaml
    └── network-policy.yaml
```

## Service Mesh Basics

### Istio VirtualService
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: api-service
  namespace: production
spec:
  hosts:
  - api-service
  http:
  - match:
    - headers:
        version:
          exact: v2
    route:
    - destination:
        host: api-service
        subset: v2
      weight: 100
  - route:
    - destination:
        host: api-service
        subset: v1
      weight: 90
    - destination:
        host: api-service
        subset: v2
      weight: 10
```

## Troubleshooting

### Common Issues

**Pod stuck in Pending:**
```bash
kubectl describe pod <pod-name>
kubectl get events --sort-by=.lastTimestamp
```

**Pod stuck in ImagePullBackOff:**
```bash
kubectl describe pod <pod-name>
kubectl get secret <secret-name> -o yaml
```

**High Memory Usage:**
```bash
kubectl top pods -n production
kubectl describe node <node-name>
```

**RBAC Issues:**
```bash
kubectl auth can-i get pods --as=system:serviceaccount:default:default
kubectl get rolebindings -n production
kubectl describe role <role-name> -n production
```
