# 7. Conventions: coefficiency

How code is written here. Agents read this file before every task. Detailed reference notes stay in `docs/project/conventions/` (Java, Jooby, general, testing patterns, security checklist); the project skills in `.claude/skills/` carry the rules agents must apply.

## Code style and naming
- Checkstyle (`build-tools/checkstyle.xml`) and SpotBugs run in the Gradle build; a change must not add findings.
- **English only** for every identifier:

| What | Rule | Good | Bad |
|---|---|---|---|
| Classes | PascalCase | `ConsultantService` | `ServicioConsultor` |
| Methods, variables | camelCase | `calculateCoef()` | `calcularCoef()` |
| Constants, env vars | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` | `MAX_INTENTOS` |
| Packages | lowercase | `io.bitnomio.coeff.billing` | `io.bitnomio.coeff.facturacion` |
| DB tables, columns | snake_case | `created_at` | `fecha_creacion` |
| API endpoints | kebab-case | `/api/file-import` | `/api/importar-archivo` |
| i18n keys | dotted English | `menu.main` | `menu.principal` |

- Repeated map keys and settings keys are named constants, not inline literals.

## Patterns to use, and what to avoid
| Concern | Use | Avoid |
|---|---|---|
| Dependency injection | Avaje Inject: `@Singleton`, constructor `@Inject`, `@Factory` + `@Bean` | CDI `@ApplicationScoped`, `@Produces` |
| REST | Jooby MVC (`io.jooby.annotation.*`), `mvc(new Controller_())` | JAX-RS, `mvc(Controller.class)` |
| Persistence | Class-based JDBI repositories, explicit binding helpers, `*Row` records | JDBI in controllers, global argument factories, ORMs |
| Interception | Avaje `@Aspect` + `AspectProvider` | CDI interceptors |
| Transactions | The JDBI handle (`inTransaction`) | `@Transactional` |
| Frontend data | TanStack Query hooks in `hooks/`, typed `api.ts` functions | fetch calls inside components |
| Frontend text | `<FormattedMessage>` with keys in `en.ts` and `es.ts` | hard-coded labels |
| UI styling | Design tokens in `DESIGN.md` | ad-hoc colours and spacing |

## Testing
- JUnit 5 with AssertJ (`assertThat`) for new tests. Existing tests that use JUnit assertions are migrated when touched.
- Name tests after behaviour, and include the acceptance-criterion id they prove, e.g. `@DisplayName("AC-6.1-2: billing endpoints keep their responses")`.
- Unit tests in `src/test`; integration tests with Testcontainers in the `intTest` source set.
- Prefer real objects and fakes over mocks; mock only ports (see `docs/project/conventions/testing-patterns.md`).
- Frontend: component tests for pages that hold logic (none yet; open task 9.4).

## Commits
Conventional Commits; see `8-WORKFLOW.md`. Scopes are feature names (`auth`, `billing`, `client`, `simulator`, ...), `frontend`, `db`, `build` or `ci`.

## Definition of Done additions
- `./gradlew build` passes with no new Checkstyle or SpotBugs findings.
- Frontend changes: `npm run lint` and `npx tsc --noEmit` pass, and both i18n bundles have the same keys.
- Schema changes come with a new Flyway migration that works on a fresh database and on a restored dump.
