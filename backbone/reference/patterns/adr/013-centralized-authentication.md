<!-- Migrated from adrs/adr-001-centralized-authentication.md on 2026-02-23 -->

# Centralized Authentication via B2F-Proxy

## Status

Accepted

## Context and Problem Statement

The project requires a robust and simplified security model. Individual microservices handling JWT validation and user context introduces complexity, potential for inconsistency, and tight coupling to specific JWT implementations. Furthermore, a centralized authentication point is desirable for easier management and auditing.

## Decision Drivers

* Reduce security complexity within individual microservices
* Enable centralized security management and auditing
* Simplify user context propagation across services
* Maintain backward compatibility with Keycloak OAuth2 integration
* Enhance inter-service communication security

## Considered Options

* **Distributed JWT validation** - Each service validates tokens independently (current approach, creates complexity)
* **Centralized authentication via B2F-Proxy** - Single authentication point, gateway handles all token validation (chosen)
* **External security service** - Separate authentication microservice (introduces additional latency)

## Decision Outcome

Chosen option: **Centralized authentication via B2F-Proxy**, because it eliminates JWT validation complexity from individual services, enables unified security policy management, and simplifies user context propagation through headers.

### Structure

B2F-Proxy serves as the sole authentication and trust entry point:

1. All incoming requests authenticated by B2F-Proxy via Keycloak OAuth2 tokens
2. Individual `myinvestor-08086` microservices remove JWT validation logic
3. Downstream services trust user context headers (`X-User-Id`, `X-User-Email`, `X-User-Roles`) from B2F-Proxy
4. B2F-Proxy introduces HMAC-SHA256 signing for service-to-service requests
5. HMAC secrets managed via environment variables with rotation per deployment

### Consequences

**Good:**
* Simplified microservices - reduced security logic and dependencies
* Centralized security management - easier policy updates and audit
* Enhanced security via HMAC - protects against header spoofing
* Improved secret management - automated rotation enhances posture
* Consistent user context - uniformly passed from gateway

**Bad:**
* Increased responsibility on B2F-Proxy - becomes critical component
* Potential performance overhead - HMAC signing adds computational cost
* Trust assumption - services implicitly trust B2F-Proxy headers

## Implementation Notes

* Implement HMAC Service-to-Service authentication (Phase 2.1)
* Add header injection in B2F-Proxy (extract user info from Keycloak JWT)
* Implement HMAC signing in B2F-Proxy for downstream requests
* Remove JWT validation from `myinvestor-08086` services
* Simplify B2F-Proxy filters - remove redundant MyInvestor JWT validation
* Update environment variables, Docker Compose, CI/CD, and documentation

## References

* B2F-Proxy authentication filters
* Keycloak integration configuration
* HMAC service authentication (ADR-0010)
* `documentation/adr/0010-hmac-service-auth.md`
