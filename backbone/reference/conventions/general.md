# General Programming Conventions

*Framework-agnostic principles applicable to all languages and frameworks.*

---

## Core Principles

### KISS - Keep It Simple, Stupid
Strive for simplicity in your code. If you've written a complex if-else chain, perhaps a switch statement or a dictionary would simplify the structure.

**Rule**: At least on early stages, keep solutions simple. Complexity accumulates naturally - fight it early.

### DRY - Don't Repeat Yourself
A key tenet for reducing redundancy. If you find yourself replicating the same code block more than twice, it's high time to think about abstraction.

**Rule**: Extract repeated logic into reusable functions, classes, or modules.

### YAGNI - You Aren't Gonna Need It
Warn against adding functionality until deemed necessary.

**Rule**: Don't optimize upfront. Don't add features "just in case". Build what you need now, not what you might need later.

### DAMP - Descriptive And Meaningful Phrases
Names should be descriptive and meaningful. Variable names like `sl` or `userMap` when they mean `activeUserIds` and `usersById` lead to confusion.

**Rule**: Use intention-revealing names. Don't rely on mental mapping.

### SOC - Separation of Concerns
Different areas of functionality should be managed by distinct and minimally overlapping modules.

**Rule**: One module per responsibility. Data fetching, storage, and UI should be separate.

---

## Error Handling

### Rules

1. **Use Exceptions rather than error codes**: Don't return error flags or error codes. Work with exceptions.

2. **Try-Catch-Finally**: Use try-catch statements in sections that might fail. Use finally for cleanup.

3. **Provide context**: Give detailed information about exceptions - what happened, where, and what to do.

4. **Don't return null, don't pass null**: Avoid null. Use Optional, empty collections, or null objects instead.

---

## API Design

### RESTful Conventions

| Method | Purpose | Idempotent |
|--------|---------|------------|
| `GET` | Retrieve a resource | Yes |
| `POST` | Create a new resource | No |
| `PUT` | Replace a resource | Yes |
| `PATCH` | Partial update | No |
| `DELETE` | Remove a resource | Yes |

### Status Codes

| Code | Meaning |
|------|---------|
| `200 OK` | Successful request |
| `201 Created` | Resource created |
| `400 Bad Request` | Client error |
| `401 Unauthorized` | Authentication required |
| `403 Forbidden` | No permission |
| `404 Not Found` | Resource doesn't exist |
| `500 Internal Server Error` | Server error |

### Versioning

Common strategies:
- URL versioning: `/v1/resource`
- Header versioning: `Accept: application/vnd.api.v1+json`
- Query parameter: `/resource?version=1`

---

## General Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| Variables | camelCase | `userName`, `orderTotal` |
| Functions | camelCase + verb | `getUserById()`, `calculateTotal()` |
| Classes | PascalCase | `UserService`, `OrderRepository` |
| Constants | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Files | kebab-case | `user-service.js`, `order_controller.py` |
| Databases | snake_case | `user_orders`, `created_at` |

---

## Version

See `conventions-general.md` for last update date.
For language-specific conventions, see:
- `java-conventions.md` - Java/Spring/Quarkus
- `php-conventions.md` - PHP/Laravel