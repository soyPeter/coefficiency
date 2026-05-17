<!-- FRAMEWORK: GENERAL -->
---
framework: general
name: security-hardening
description: Security-first development practices. Use when handling user input, authentication, data storage, or external integrations. Use when building any feature that accepts untrusted data.
---

# Security and Hardening

Security-first development practices. Treat external input as hostile, secrets as sacred, authorization checks as mandatory.

## When to Use

- Building anything that accepts user input
- Implementing authentication or authorization
- Storing or transmitting sensitive data
- Integrating with external APIs or services
- Adding file uploads, webhooks, or callbacks
- Handling payment or PII data

## The Three-Tier Boundary System

### Always Do (No Exceptions)

- **Validate all external input** at the system boundary (API routes, form handlers)
- **Parameterize all database queries** — never concatenate user input into SQL
- **Encode output** to prevent XSS (use framework auto-escaping, do not bypass it)
- **Use HTTPS** for all external communication
- **Hash passwords** with bcrypt/scrypt/argon2 (never store plaintext)
- **Set security headers** (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- **Use httpOnly, secure, sameSite cookies** for sessions
- **Run dependency audit** (`npm audit` / `mvn dependency:check`) before every release

### Ask First (Requires Human Approval)

- New authentication flows or changing auth logic
- Storing new categories of sensitive data (PII, payment info)
- Adding new external service integrations
- Changing CORS configuration
- Adding file upload handlers
- Modifying rate limiting or throttling
- Granting elevated permissions or roles

### Never Do

- **Never commit secrets** to version control (API keys, passwords, tokens)
- **Never log sensitive data** (passwords, tokens, full credit card numbers)
- **Never trust client-side validation** as a security boundary
- **Never disable security headers** for convenience
- **Never use eval() or innerHTML** with user-provided data
- **Never store sessions in client-accessible storage** (localStorage for auth tokens)
- **Never expose stack traces** or internal error details to users

## OWASP Top 10 Prevention

### 1. Injection (SQL, NoSQL, OS Command)

```java
// BAD: SQL injection via string concatenation
String query = "SELECT * FROM users WHERE id = '" + userId + "'";

// GOOD: Parameterized query (JDBC)
PreparedStatement stmt = conn.prepareStatement(
    "SELECT * FROM users WHERE id = ?");
stmt.setString(1, userId);

// GOOD: ORM (Panache/Quarkus)
User.findById(userId);
```

### 2. Broken Authentication

```java
// Password hashing (Quarkus with SmallRye)
@Inject PasswordProvider passwordProvider;

String hashed = passwordProvider.hash(plaintext); // Uses bcrypt
boolean isValid = passwordProvider.verify(plaintext, hashed);

// Session management
@ApplicationScoped
public class SessionManager {
    public Cookie createSession(String userId) {
        return Cookie.builder("session", generateToken(userId))
            .httpOnly(true)
            .secure(true)
            .sameSite(SameSite.LAX)
            .maxAge(24 * 60 * 60) // 24 hours
            .build();
    }
}
```

### 3. Cross-Site Scripting (XSS)

```java
// BAD: Rendering user input as raw HTML
return Response.ok("<div>" + userInput + "</div>").build();

// GOOD: Template auto-escaping (Qute/Quarkus)
// Templates escape by default — do not bypass with {raw} unless necessary
return Templates.userProfile(user).render();
```

### 4. Broken Access Control

```java
// Always check authorization, not just authentication
@GET
@Path("/tasks/{id}")
@Authenticated
public Task getTask(@PathParam("id") String id) {
    Task task = taskService.findById(id);
    
    // Check that the authenticated user owns this resource
    if (!task.getOwnerId().equals(securityIdentity.getPrincipal().getName())) {
        throw new ForbiddenException("Not authorized to access this task");
    }
    
    return task;
}
```

### 5. Security Misconfiguration

```properties
# Quarkus security headers
quarkus.http.header.X-Content-Type-Options=value
quarkus.http.header.X-Frame-Options=DENY
quarkus.http.header.Content-Security-Policy=default-src 'self'

# CORS — restrict to known origins
quarkus.http.cors=true
quarkus.http.cors.origins=https://myapp.com,https://app.myapp.com
quarkus.http.cors.methods=GET,POST,PUT,DELETE
```

### 6. Sensitive Data Exposure

```java
// Never return sensitive fields in API responses
public record PublicUser(
    String id,
    String displayName,
    String email
    // passwordHash, resetToken intentionally omitted
) {}

// Use environment variables for secrets
@ConfigProperty(name = "stripe.api.key")
String stripeApiKey;
```

## Input Validation Patterns

### Bean Validation at Boundaries

```java
public class CreateTaskRequest {
    @NotBlank @Size(max = 200)
    private String title;
    
    @Size(max = 2000)
    private String description;
    
    @Pattern(regexp = "low|medium|high")
    private String priority = "medium";
}
```

### File Upload Safety

```java
// Restrict file types and sizes
Set<String> ALLOWED_TYPES = Set.of("image/jpeg", "image/png", "image/webp");
long MAX_SIZE = 5 * 1024 * 1024; // 5MB

void validateUpload(UploadedFile file) {
    if (!ALLOWED_TYPES.contains(file.contentType())) {
        throw new ValidationException("File type not allowed");
    }
    if (file.size() > MAX_SIZE) {
        throw new ValidationException("File too large (max 5MB)");
    }
}
```

## Rate Limiting

```java
// Quarkus rate limiting
@RateLimit(value = 100, window = 15, windowUnit = ChronoUnit.MINUTES)
@Path("/api")
public class ApiResource { }

// Stricter limit for auth endpoints
@RateLimit(value = 10, window = 15, windowUnit = ChronoUnit.MINUTES)
@Path("/api/auth")
public class AuthResource { }
```

## Secrets Management

```
.env files:
  .env.example  -> Committed (template with placeholder values)
  .env          -> NOT committed (contains real secrets)
  .env.local    -> NOT committed (local overrides)

.gitignore must include:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**Always check before committing:**
```bash
# Check for accidentally staged secrets
git diff --cached | grep -i "password\|secret\|api_key\|token"
```

## Security Review Checklist

```markdown
### Authentication
- [ ] Passwords hashed with bcrypt/scrypt/argon2 (salt rounds >= 12)
- [ ] Session tokens are httpOnly, secure, sameSite
- [ ] Login has rate limiting
- [ ] Password reset tokens expire

### Authorization
- [ ] Every endpoint checks user permissions
- [ ] Users can only access their own resources
- [ ] Admin actions require admin role verification

### Input
- [ ] All user input validated at the boundary
- [ ] SQL queries are parameterized
- [ ] HTML output is encoded/escaped

### Data
- [ ] No secrets in code or version control
- [ ] Sensitive fields excluded from API responses
- [ ] PII encrypted at rest (if applicable)

### Infrastructure
- [ ] Security headers configured (CSP, HSTS, etc.)
- [ ] CORS restricted to known origins
- [ ] Dependencies audited for vulnerabilities
- [ ] Error messages don't expose internals
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is an internal tool, security doesn't matter" | Internal tools get compromised. Attackers target the weakest link. |
| "We'll add security later" | Security retrofitting is 10x harder than building it in. |
| "No one would try to exploit this" | Automated scanners will find it. |
| "The framework handles security" | Frameworks provide tools, not guarantees. |
| "It's just a prototype" | Prototypes become production. |

## Red Flags

- User input passed directly to database queries, shell commands, or HTML rendering
- Secrets in source code or commit history
- API endpoints without authentication or authorization checks
- Missing CORS or wildcard origins
- No rate limiting on authentication endpoints
- Stack traces or internal errors exposed to users
- Dependencies with known critical vulnerabilities

## Verification

After implementing security-relevant code:

- [ ] `npm audit` / `mvn dependency:check` shows no critical/high vulnerabilities
- [ ] No secrets in source code or git history
- [ ] All user input validated at system boundaries
- [ ] Authentication and authorization checked on every protected endpoint
- [ ] Security headers present in response
- [ ] Error responses don't expose internal details
- [ ] Rate limiting active on auth endpoints
