# Keycloak for Centralized User Management

## Status

Accepted

## Context and Problem Statement

The Bitnomio platform needs centralized user management and authentication that can be shared across multiple microservices and external clients. Each service implementing its own authentication creates duplication, security inconsistencies, and operational complexity.

## Decision Drivers

* **Centralization**: Single source of truth for user credentials and permissions
* **Standards compliance**: OAuth2 and OpenID Connect support
* **Multi-service**: Shared identity across all Bitnomio microservices
* **External clients**: Support for third-party applications via OAuth2
* **Auditability**: Comprehensive audit logs for compliance
* **Identity federation**: Support for future federation with external identity providers

## Considered Options

* **Keycloak** - Open-source identity provider with OAuth2/OIDC support
* **Auth0** - Commercial SaaS identity platform
* **AWS Cognito** - AWS-managed identity service
* **Custom JWT-based auth** - In-service authentication without centralized provider

## Decision Outcome

Chosen option: "Keycloak", because it provides industry-standard OAuth2/OIDC implementation, is open-source and self-hosted (operational control), integrates with multiple protocols, and can federate with external identity providers while remaining cost-effective.

### Implementation

**User Creation Flow:**
1. **Signup Service** receives signup request with email and password
2. **CreateSignupUseCase** calls `KeycloakUserClient.createUser(email, username, password)`
3. **Keycloak Admin API** creates user and sets initial credentials
4. **Local database** stores signup record with Keycloak user ID
5. **Outbox Pattern** publishes `SignupCreatedEvent` for email verification

**Token Validation Flow:**
1. **Client** authenticates with Keycloak and receives OAuth2 access token
2. **B2F-Proxy/Services** validate token against Keycloak JWK Set
3. **Token claims** include issuer, subject (user ID), roles, and expiration
4. **Graceful degradation**: Services continue if Keycloak temporarily unavailable (cached tokens)

**Admin Token Management:**
- `KeycloakTokenProvider` caches admin tokens with automatic refresh
- Token refresh triggered at 80% of expiration time
- Uses `client_credentials` OAuth2 grant for service-to-Keycloak auth
- Secrets managed via AWS Secrets Manager or environment variables

### Configuration

**Required Environment Variables:**
```bash
KEYCLOAK_SERVER_URL=http://keycloak:8081
KEYCLOAK_REALM=b2f
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_CLIENT_SECRET=${SECRET}
```

**Application Configuration:**
```yaml
keycloak:
  server-url: ${KEYCLOAK_SERVER_URL}
  realm: ${KEYCLOAK_REALM}
  admin-client-id: ${KEYCLOAK_ADMIN_CLIENT_ID}
  admin-client-secret: ${KEYCLOAK_ADMIN_CLIENT_SECRET}
  
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_REALM}
          jwk-set-uri: ${KEYCLOAK_SERVER_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/certs
```

**Service Integration:**
- See: `services/signup/src/main/java/io/bitnomio/signup/infra/keycloak/KeycloakUserClient.java`
- See: `services/signup/src/main/java/io/bitnomio/signup/app/CreateSignupUseCase.java`

### Consequences

* Good, because centralized user management reduces duplication
* Good, because OAuth2/OIDC provides industry-standard authentication
* Good, because can support external client applications
* Good, because Keycloak provides audit logs for compliance
* Good, because federation support enables future integration with LDAP/SAML
* Bad, because adds operational dependency on Keycloak service
* Bad, because requires secure credential storage for admin tokens
* Bad, because clock skew between Keycloak and services could cause token validation failures
* Bad, because Keycloak temporary unavailability affects user signup

## Resilience Patterns

- **Circuit Breaker**: Protects against cascading failures if Keycloak unavailable
- **Retry**: Exponential backoff for transient network failures
- **Token Caching**: Local caching of admin tokens reduces Keycloak load
- **Graceful degradation**: Services continue with degraded functionality if Keycloak fails

## References

* Keycloak documentation: https://www.keycloak.org/docs
* OAuth2 RFC 6749: https://tools.ietf.org/html/rfc6749
* OpenID Connect Core: https://openid.net/specs/openid-connect-core-1_0.html
* `documentation/KEYCLOAK_AUTH_SETUP.md` - Complete Keycloak setup guide
* `documentation/SECURITY.md` - Security architecture overview
