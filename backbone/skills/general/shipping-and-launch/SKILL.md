<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: shipping-and-launch
description: Prepares production launches. Use when preparing to deploy to production, when you need a pre-launch checklist, or when planning staged rollouts.
---

# Shipping and Launch

Ship with confidence. Every launch should be reversible, observable, and incremental.

## When to Use

- Deploying a feature to production for the first time
- Releasing a significant change
- Migrating data or infrastructure
- Any deployment carrying risk (all of them)

## Pre-Launch Checklist

### Code Quality
- [ ] All tests pass (unit, integration, e2e)
- [ ] Build succeeds with no warnings
- [ ] Code reviewed and approved
- [ ] No TODO comments that should be resolved
- [ ] Error handling covers expected failure modes

### Security
- [ ] No secrets in code or version control
- [ ] Dependency audit clean
- [ ] Input validation on all user-facing endpoints
- [ ] Auth and authz checks in place
- [ ] Security headers configured
- [ ] Rate limiting on auth endpoints
- [ ] CORS configured to specific origins

### Performance
- [ ] Core Web Vitals within "Good" thresholds
- [ ] No N+1 queries in critical paths
- [ ] Images optimized
- [ ] Bundle size within budget
- [ ] Database queries have appropriate indexes
- [ ] Caching configured

### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader conveys content
- [ ] Color contrast meets WCAG 2.1 AA
- [ ] Focus management correct
- [ ] Error messages descriptive

### Infrastructure
- [ ] Environment variables set
- [ ] Database migrations applied or ready
- [ ] DNS and SSL configured
- [ ] CDN configured for static assets
- [ ] Logging and error reporting configured
- [ ] Health check endpoint exists

### Documentation
- [ ] README updated
- [ ] API docs current
- [ ] ADRs written for architectural decisions
- [ ] Changelog updated

## Feature Flag Strategy

Ship behind feature flags to decouple deployment from release:

```
1. DEPLOY with flag OFF     → Code in production but inactive
2. ENABLE for team/beta     → Internal testing
3. GRADUAL ROLLOUT          → 5% → 25% → 50% → 100%
4. MONITOR at each stage
5. CLEAN UP                 → Remove flag after full rollout (within 2 weeks)
```

**Rules:**
- Every feature flag has an owner and expiration date
- Clean up flags within 2 weeks of full rollout
- Don't nest feature flags
- Test both flag states in CI

## Staged Rollout

```
1. Deploy to staging
   └── Full test suite, manual smoke test

2. Deploy to production (flag OFF)
   └── Verify deployment, check error monitoring

3. Enable for team (24-hour monitoring)

4. Canary 5% (monitor error rates, latency)
   └── Compare: canary vs baseline

5. Gradual increase 25% → 50% → 100%

6. Full rollout (monitor 1 week, clean up flag)
```

## Rollback Decision Thresholds

| Metric | Advance | Hold | Roll back |
|--------|---------|------|-----------|
| Error rate | Within 10% of baseline | 10-100% above | >2x baseline |
| P95 latency | Within 20% of baseline | 20-50% above | >50% above |
| JS errors | No new types | <0.1% sessions | >0.1% sessions |
| Business metrics | Neutral/positive | Decline <5% | Decline >5% |

## Rollback Strategy

Every deployment needs a rollback plan:

```markdown
## Rollback Plan

### Trigger Conditions
- Error rate > 2x baseline
- P95 latency > [X]ms

### Rollback Steps
1. Disable feature flag OR deploy previous version
2. Verify rollback: health check, error monitoring
3. Communicate to team

### Database Considerations
- Migration has rollback script
- Data from new feature: preserved

### Time to Rollback
- Feature flag: < 1 minute
- Redeploy: < 5 minutes
```

## Post-Launch Verification

In the first hour after launch:
1. Health endpoint returns 200
2. No new error types in monitoring
3. No latency regression
4. Critical user flow works manually
5. Logs flowing and readable
6. Rollback mechanism verified

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "It works in staging, it'll work in production" | Production has different data, traffic, edge cases. |
| "We don't need feature flags for this" | Every feature benefits from a kill switch. |
| "Monitoring is overhead" | Not having monitoring means discovering problems from user complaints. |
| "Rolling back is admitting failure" | Rolling back is responsible engineering. |

## Red Flags

- Deploying without rollback plan
- No monitoring or error reporting
- Big-bang releases (everything at once)
- Feature flags with no expiration
- No one monitoring the deploy
- "It's Friday afternoon, let's ship it"

## Verification

Before deploying:
- [ ] Pre-launch checklist completed
- [ ] Feature flag configured (if applicable)
- [ ] Rollback plan documented
- [ ] Monitoring dashboards set up

After deploying:
- [ ] Health check returns 200
- [ ] Error rate normal
- [ ] Latency normal
- [ ] Critical user flow works
- [ ] Logs flowing
- [ ] Rollback tested or verified ready
