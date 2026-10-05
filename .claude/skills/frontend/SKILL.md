---
name: frontend
description: Write or review the coefficiency React 19 + TypeScript SPA - pages, components and hooks, TanStack Query data access through api.ts, react-intl i18n with EN/ES parity, react-hook-form + zod forms, Tailwind/shadcn UI per DESIGN.md, file size limits. Use for anything under services/coeff/frontend/src.
applies-to: react 19, typescript 5, vite 7, coefficiency
last-verified: 2026-10-05
sources: coefficiency architecture notes, ADR-005/ADR-006, DESIGN.md and the existing frontend code
---

# Frontend (React SPA)

The accepted ADRs and `backbone/4-KNOWLEDGE.md` override this skill. The visual design system is `DESIGN.md` (read it before changing UI).

## Structure

```
services/coeff/frontend/src/
├── api.ts          # every HTTP call: typed functions on top of request<T>() (auth header, 401/503 handling)
├── types.ts        # API types (mirror the backend DTO records)
├── pages/          # one page per route; composition only
├── components/     # reusable components (ui/ = shadcn primitives, layouts/)
├── hooks/          # data and behaviour hooks (TanStack Query, timers, uploads); index.ts barrel
├── i18n/           # en.ts, es.ts, messages.ts
├── routing/        # HashRouter routes
└── lib/            # helpers
```

## Rules

1. **Data access only through `api.ts`** functions and TanStack Query hooks in `hooks/`. Components never call `fetch` directly.
2. **Errors:** `request<T>()` throws `AuthError` on 401 (log out) and `ServiceUnavailableError` on 503 (database unavailable). Handle both in the UI; never treat 503 as an authentication failure.
3. **Text:** every user-visible string is `<FormattedMessage id=...>` or `intl.formatMessage`. Keys are English and dotted (`simulator.saved`), and **`en.ts` and `es.ts` always have the same keys**. A guardrail warns on hard-coded text in `.tsx`.
4. **Types:** no `any`. API shapes live in `types.ts` and match the backend DTO records; when the backend changes, change `types.ts` in the same task.
5. **Forms:** `react-hook-form` with a `zod` schema; validate on the client for UX, but the backend remains the authority (ADR-006).
6. **Size:** a page over about 300 lines, or a hook over about 150, is split into sub-components and hooks (task 6.3 is the reference: `SimulatorPage`). Logic lives in hooks; pages compose.
7. **UI:** use the shadcn/Tailwind primitives in `components/ui` and the tokens in `DESIGN.md`; no ad-hoc colours or spacing. Charts use the existing libraries (recharts/apexcharts), not a third one.
8. **Derived data:** compute with `useMemo` instead of adding endpoints for data the page already has (ADR-005 pattern).
9. **Security:** the token lives in `localStorage` (single-user local app); never log it, and never render server data with `dangerouslySetInnerHTML`.

## Commands

```bash
cd services/coeff/frontend
npm run lint          # ESLint (fixes)
npx tsc --noEmit      # type check
npm run build         # tsc + vite build
npm run dev           # dev server (proxy to the Jooby backend)
```

There is no test runner yet. Component tests (task 9.4) need an ADR choosing one (e.g. Vitest + Testing Library) before they are written.

## Checklist

- [ ] No direct `fetch`; new calls added to `api.ts` and `types.ts`.
- [ ] All new text is i18n'd in both `en.ts` and `es.ts` with English keys.
- [ ] 401 and 503 handled; no `any`; lint and type check pass.
- [ ] No page or hook pushed past the size limits; logic in hooks.

## Linked skills
- `code-quality`: naming, function size and duplication rules for TypeScript too.
- `api-design`: the contracts `api.ts` consumes.
- `security`: token handling and rendering of untrusted data.
- `module-testing`: once a test runner is adopted (task 9.4).
