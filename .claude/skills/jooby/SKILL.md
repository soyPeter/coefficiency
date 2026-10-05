---
name: jooby
description: Write or review Jooby 4.5 web code with Avaje Inject in coefficiency - MVC controllers, module setup and installation order, DI with @Singleton/@Factory/@Bean, Avaje AOP, error mapping, transactions through JDBI. Use for infra/ code, controllers and application wiring.
applies-to: jooby 4.5, avaje-inject 12, java>=21
last-verified: 2026-10-05
sources: adapted from coefficiency docs/project/conventions/jooby.md (project conventions); stack per ADR-002
---

# Jooby with Avaje Inject

The accepted ADRs and `backbone/4-KNOWLEDGE.md` override this skill. Full reference with longer examples: `docs/project/conventions/jooby.md`.

## Hard rules (guardrails enforce the ones marked G)

1. MVC annotations come from `io.jooby.annotation.*`; never JAX-RS `jakarta.ws.rs.*` (G).
2. DI is Avaje Inject (compile time): `@Singleton` and constructor `@Inject`; producers are `@Factory` classes with `@Bean` methods. Never CDI `@ApplicationScoped` or `@Produces` (G).
3. Interception is Avaje AOP (`@Aspect` + `AspectProvider`), never CDI `@InterceptorBinding` (G).
4. Transactions go through the JDBI handle (`jdbi.inTransaction(...)`), never `@Transactional` (G).
5. Register controllers with `mvc(new MyController_())` (the APT-generated class), never `mvc(MyController.class)` (G).
6. Controllers live in `<feature>/infra/rest/` and **never receive `Jdbi`**: they call an application service (G, task 6.1).
7. Controllers translate HTTP to use-case calls and back: validate input, call one service method, map the result to a DTO record. No business logic, no SQL.

## Controller shape

```java
@Path("/api/consultants")
public class ConsultantController {
    private final ConsultantService service;

    @Inject
    public ConsultantController(ConsultantService service) { this.service = service; }

    @GET @Path("/{id}")
    public ConsultantResponse getById(@PathParam long id) {
        return ConsultantResponse.from(service.get(id));        // service throws NotFound -> 404
    }

    @POST
    public ConsultantResponse create(@Body CreateConsultantRequest request) {
        request.validate();                                     // BadRequestException on violations
        return ConsultantResponse.from(service.create(request.toCommand()));
    }
}
```

Parameter annotations: `@PathParam`, `@QueryParam`, `@Body`, `@FormParam`, `@Header`, `@Cookie`. Request and response DTOs are records in `infra/rest/`, never domain types.

## Wiring and setup

- Module installation order in the application class:
  1. `AvajeInjectModule.of()`;
  2. `Jackson2Module`;
  3. the framework modules (`JdbiModule`, `FlywayModule`);
  4. `mvc(new X_())` for each controller;
  5. the app modules (exception mapper).
- Annotation processors: `avaje-inject-generator` **before** `jooby-apt`. Compile with `-parameters`.
- Dependencies provided by Jooby modules (e.g. `Jdbi`) are declared with `@InjectModule(requires = ...)` and consumed only in `infra/`.
- Shared singletons such as `ObjectMapper` and `SecureRandom` are injected, not created per call.

## Errors and status codes

- Map exceptions centrally in the `ExceptionMapper` module, with `app.errorCode(...)` and a JSON error body. Don't catch and swallow in controllers.
- Input violations throw `BadRequestException` (400); missing entities give 404; authentication failures give 401 from `AuthFilter`; "database locked or encrypted, unavailable" gives 503. The frontend distinguishes 401 from 503.
- Never leak stack traces or SQL in error bodies.

## Security in this app

- Every `/api/*` route except the auth setup/login paths passes `AuthFilter` (HMAC token). New endpoints are protected by default; adding an exempt path needs an ADR.
- Passwords use BCrypt; the HMAC secret comes from configuration, never from code.
- CORS stays limited to localhost origins.

## Checklist

- [ ] No `jakarta.ws.rs`, CDI or `@Transactional` imports; controllers registered via `X_` classes.
- [ ] No `Jdbi` in controllers; one service call per endpoint; DTO records at the boundary.
- [ ] Input validated, errors mapped centrally, correct status codes.
- [ ] New endpoints have kebab-case English paths and an `api-design`-conformant contract.

## Linked skills
- `api-design`: status codes, error format, pagination and compatibility for endpoints.
- `jdbi`: the persistence adapters the services call.
- `architecture`: what belongs in domain, app and infra.
- `security`: authentication, authorization and input handling at the boundary.
- `java`: language rules for all Java code.
