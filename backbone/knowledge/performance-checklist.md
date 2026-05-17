# Performance Checklist

Pre-launch performance verification.

## Frontend Checklist

- [ ] LCP < 2.5s
- [ ] INP < 200ms
- [ ] CLS < 0.1
- [ ] Images optimized (compression, responsive sizes, lazy loading)
- [ ] Bundle size < 200KB gzipped (initial)
- [ ] CSS < 50KB gzipped
- [ ] Fonts < 100KB total
- [ ] No render-blocking resources
- [ ] Code splitting for routes

## Backend Checklist

- [ ] API response < 200ms (p95)
- [ ] No N+1 queries
- [ ] Database queries have indexes
- [ ] Pagination on list endpoints
- [ ] Caching configured (static assets, repeated queries)
- [ ] Connection pooling configured
- [ ] No unbounded data fetching

## Measurement Commands

```bash
# Lighthouse
npx lighthouse https://example.com --preset=desktop

# Bundle analysis
npx webpack-bundle-analyzer dist/stats.json

# Database query timing
# Enable slow query log in PostgreSQL
# log_min_duration_statement = 100

# JVM profiling
./gradlew jvmRun -Dquarkus.profile=prod
# Use VisualVM or async-profiler for CPU/memory
```

## Anti-Patterns to Check

- [ ] N+1 queries
- [ ] Unbounded data fetching (no pagination)
- [ ] Missing image optimization
- [ ] Large bundle size (no code splitting)
- [ ] Synchronous operations in hot paths
- [ ] Missing caching
- [ ] Unnecessary re-renders
