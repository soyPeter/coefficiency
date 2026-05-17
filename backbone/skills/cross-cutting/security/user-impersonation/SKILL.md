<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: user-impersonation
description: User impersonation patterns for secure admin access and troubleshooting. Use when implementing admin impersonation, debugging user-specific issues, or building audit-compliant delegation.
origin: agentic-backbone
version: "1.0"
---

# User Impersonation Patterns

Secure patterns for administrators to access and operate as other users for debugging and support.

## When to Use

- Troubleshooting user-specific permission issues
- Auditing access to compliance requirements
- Support teams needing to see exactly what users see
- Testing user-specific content and permissions
- Project type: `security`, `auth`, `admin-tools`

## Core Concepts

### What is User Impersonation?

User Impersonation allows administrators to:
1. Access the system as if logged in as another user
2. View the same menus, modules, and content
3. Have all actions logged as the impersonated user

### Super Token Pattern

```
┌─────────────────────────────────────────────────────────┐
│                    Request with Super Token                │
├─────────────────────────────────────────────────────────┤
│  x-access-token: <user_token>                           │
│  super-x-access-token: <admin_impersonation_token>     │
└─────────────────────────────────────────────────────────┘
```

Two tokens maintained:
- **x-access-token**: Original user authentication
- **super-x-access-token**: Admin impersonation token (if active)

## Implementation

### 1. Token Structure

```java
public class ImpersonateResponseInfo {
    private String impersonateAccessToken;  // Temporary user token
    private String userAccessToken;          // Admin's own token
}
```

### 2. Impersonation Session

```java
@Component
public class ImpersonateUserSession extends UserSession {
    // Stores impersonated user's session details
    private String impersonatedUserId;
    private String impersonatedUserEmail;
    private List<Permission> impersonatedPermissions;
}
```

### 3. Token Validation

```java
public void setImpersonateUserSession(final String token) {
    final UserDetails userDetails = TokenHelper.decode(token);

    if (!ObjectUtils.allNotNull(userDetails.getUserId(), userDetails.getTenantId())) {
        throw new UnauthorizedException("User not present");
    }

    final ImpersonateUserSession user = impersonateUserSession.get();
    user.setTenantId(userDetails.getTenantId());
    user.setId(userDetails.getUserId());
    user.setEmail(userDetails.getEmail());
}
```

### 4. Read-Only Access for Impersonated Sessions

```java
public void setUserPermission(final UserSession user) {
    // Impersonated users get read-only access
    user.setApplicationPermissions(ImmutableMap.of(
        Permissions.ERP,
        Arrays.asList(
            Permissions.ORG_SETUP_R,
            Permissions.ORGANIZATION_SETTINGS_R,
            Permissions.VIEW_REPORTS_R
        )
    ));
}
```

### 5. Audit Logging

```java
@Override
public Optional<Long> getCurrentAuditor() {
    try {
        final UserSession session =
            Objects.nonNull(impersonateUserSession.get())
                ? impersonateUserSession.get()
                : userSessionProvider.get();
        return Optional.of(session.getId());
    } catch (Exception ex) {
        return Optional.of(-1L);  // System operations
    }
}
```

## Security Considerations

| Concern | Mitigation |
|---------|------------|
| Privilege escalation | Impersonation tokens are time-limited |
| Audit trail | All actions logged as impersonated user |
| Read-only by default | Impersonated sessions have restricted permissions |
| Token storage | Separate session storage for impersonation context |
| Fallback | If impersonation fails, use original admin session |

## HTTP Headers

| Header | Purpose |
|--------|---------|
| `x-access-token` | Original user or admin token |
| `super-x-access-token` | Admin's impersonation token |

## Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Full admin access during impersonation | Admin could make changes as user | Enforce read-only permissions |
| No audit trail | Can't track what admin did | Log impersonated user ID in every action |
| Permanent impersonation tokens | Long-lived privilege | Time-limited tokens, auto-expiry |
| No user notification | User unaware admin accessed | Send notification when impersonation starts |

## Use Cases

### 1. Support Debugging

```
Support Agent: "User #1234 can't see their orders"
Admin: Impersonates User #1234 → Sees exactly what they see → Identifies permission issue
```

### 2. Compliance Auditing

```
Compliance Team: "Show me all access to customer data by admin X in the last 30 days"
System: Query audit logs where impersonator = Admin X AND action performed as other user
```

### 3. Content Verification

```
Content Team: "Does this page look right for premium users?"
Admin: Impersonates premium user → Views content as premium user
```

## Related Skills

- Skill: `security-review` — Security checklist for auth implementations
- Skill: `security-audit` — Audit logging and compliance patterns
- Skill: `backend-patterns` — API authentication patterns