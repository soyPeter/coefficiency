# HMAC-SHA256 for Service Authentication

## Status

Accepted

## Context and Problem Statement

Microservices in the Bitnomio platform need to authenticate requests from other services (e.g., B2F-Proxy) without relying solely on network-level trust. We need a cryptographic mechanism to verify that requests have not been tampered with and originate from authorized sources.

## Decision Drivers

* **Security**: Cryptographic verification of inter-service requests
* **Integrity**: Ensure requests have not been altered in transit
* **Authentication**: Verify that requests come from authorized sources
* **Simplicity**: Lightweight mechanism without complex infrastructure
* **Performance**: Minimal overhead for signature verification

## Considered Options

* **HMAC-SHA256 with shared secret** - Symmetric key cryptography with signatures
* **mTLS (mutual TLS)** - Certificate-based authentication
* **OAuth2 tokens** - Token-based authentication between services
* **API Keys** - Simple but less secure verification

## Decision Outcome

Chosen option: "HMAC-SHA256 with shared secret", because it provides strong cryptographic verification with minimal operational complexity, works well for internal service-to-service communication, and requires only a shared secret (no certificate infrastructure).

### Implementation

**Service-to-Service Flow:**
1. **B2F-Proxy**: Generates HMAC-SHA256 signature using shared secret
2. **Signature includes**: Request payload + timestamp + method + path
3. **Header transmission**: Signature sent in `X-Hmac-Signature` header
4. **Verification**: Target service recalculates signature and compares
5. **Timestamp validation**: Prevents replay attacks (e.g., 5-minute window)

**Location:** `services/libs/shared-security/` module provides `JwtValidationUseCase` for JWT-based auth; HMAC verification handled at service boundary layers.

### Consequences

* Good, because signatures prevent tampering and forgery
* Good, because no certificate infrastructure required
* Good, because works well for internal service communication
* Good, because HMAC-SHA256 is cryptographically strong and efficient
* Bad, because shared secret must be securely managed and rotated
* Bad, because clock skew between services could cause validation failures
* Bad, because less suitable for service-to-external-party communication (use OAuth2 instead)

## Related Patterns

- **Framework**: Uses same shared secret management as JWT authentication
- **Security Module**: Implemented in `shared-security` module alongside JWT validation
- **API Gateway Integration**: B2F-Proxy generates signatures for all outgoing requests
- **Configuration**: Environment variables + AWS Secrets Manager for secret storage

## References

* [Architecture Decision: JWT Validation](./0010-hmac-service-auth.md)
* `services/libs/shared-security/` - JWT validation and signature verification
* `documentation/SECURITY.md` - Comprehensive security guide
* HMAC-SHA256 standard: RFC 2104
