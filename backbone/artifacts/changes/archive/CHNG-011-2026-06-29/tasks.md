# CHNG-011: Tasks

## Granularity Rules
- ONE file per task — never create multiple files in one task
- ONE method per task — never add logic to multiple methods
- ONE endpoint/route per task — never batch routes
- ONE query per task — never batch repository methods
- ONE test scenario per task — never test multiple modes in one task
- Size tags: [XS] single item, [S] method/query/test, [M] complex orchestration
- Concrete verbs only: add, fix, remove, configure, validate, create, update, extract, refactor
- NO vague verbs: implement, build, develop, do, make, setup
- NO "and" in task titles — if you use "and", split into multiple tasks
- NO [L] — if anything seems [L], split further

## Tasks

### Phase 1: Create component files

## [x] Create StatusBadge component at components/consultants/StatusBadge.tsx
**Parent:** REQ-FE-004
**Size:** [XS]
**Details:** Create `components/consultants/StatusBadge.tsx` matching Javalin reference. Exports `StatusBadge` function component accepting `{ status?: string }`. Maps status values (`PROFITABLE`, `AT_RISK`, `BELOW_THRESHOLD`, `INSUFFICIENT_DATA`) to color classes and i18n keys from `FormattedMessage`. Renders a rounded pill badge with status text.

## [x] Create DropdownInput component at components/consultants/DropdownInput.tsx
**Parent:** REQ-FE-001
**Size:** [XS]
**Details:** Create `components/consultants/DropdownInput.tsx` matching Javalin reference. Exports `DropdownInput` function component with `DropdownInputProps` interface (`id`, `label`, `value`, `options`, `onChange`). Implements dual-mode input: free-text with autocomplete dropdown (search filter + selectable list) and native `<select>` with toggle button. Uses `useMemo` for filtered options, `useState` for open/search/allowed states.

## [x] Create ConsultantTable component at components/consultants/ConsultantTable.tsx
**Parent:** REQ-FE-002
**Size:** [S]
**Details:** Create `components/consultants/ConsultantTable.tsx` with coefficiency's current column set: name, client, position, startDate, endDate, daysInRole, coefPercentage, tariff, managerBonus. Export `ConsultantTableProps` interface with `consultants`, `sortField`, `sortDir`, `onSort`, `coefAlertThreshold`, `onShow`, `onEdit`, `onDelete`, `fmt`. Include coef percentage coloring (red below threshold, green above 125% of threshold). Render sortable column headers with `ArrowUp`/`ArrowDown` icons, action buttons (`Eye`, `Pencil`, `Trash2`), and empty-state row.

## [x] Create ConsultantFilterBar component at components/consultants/ConsultantFilterBar.tsx
**Parent:** REQ-FE-003
**Size:** [XS]
**Details:** Create `components/consultants/ConsultantFilterBar.tsx` wrapping the search input currently inline in ConsultantsPage. Export `ConsultantFilterBarProps` interface with `searchQuery`, `onSearchChange`, `onPageReset`. Render a search input with `Search` icon, calling `onPageReset` when search changes.

## [x] Create RevenueLeaderboard component at components/RevenueLeaderboard.tsx
**Parent:** REQ-FE-005
**Size:** [S]
**Details:** Create `components/RevenueLeaderboard.tsx` matching Javalin reference. Default export `RevenueLeaderboard` function component receiving `{ consultants: ConsultantBrief[], onRowClick? }`. Implement 7 sortable columns (name, client, position, tariff, fees, coef, coefMargin) with `ArrowUpDown` indicator. Include search input filtering by name/client, pagination at 10 per page with prev/next controls and page indicator. Render rank column with emoji medals for top 3. Reset page to 0 on search/sort change. Handle empty state with i18n messages.

### Phase 2: Integrate components into pages

## [x] Replace inline DropdownInput in ConsultantsPage with imported component
**Parent:** REQ-FE-001
**Size:** [S]
**Details:** Remove the inline `DropdownInput` function definition (lines 56–122) from `ConsultantsPage.tsx`. Add `import { DropdownInput } from '@/components/consultants/DropdownInput'` at the top. Remove unused imports that were only used by the inline definition (`Label` from `@/components/ui/label` if no longer used elsewhere, `useMemo` import review). Verify the two usages of `<DropdownInput>` (client, position fields) still compile.

## [x] Replace inline table in ConsultantsPage with imported ConsultantTable
**Parent:** REQ-FE-002
**Size:** [S]
**Details:** Remove the inline `<table>` JSX block (lines 524–594) and the `COLUMNS` constant (lines 136–146) and `SortField` type (lines 124–134) from `ConsultantsPage.tsx`. Add `import { ConsultantTable } from '@/components/consultants/ConsultantTable'`. Map state values to props: `consultants={paginated}`, `sortField`, `sortDir`, `onSort={handleSort}`, `coefAlertThreshold`, `onShow={setShowConsultant}`, `onEdit={openEdit}`, `onDelete={handleDelete}`, `fmt={fmt}`. Remove unused imports (`ArrowDown`, `ArrowUp`, `Eye`, `Pencil`, `Trash2` from lucide-react if no longer used elsewhere).

## [x] Replace inline search in ConsultantsPage with imported ConsultantFilterBar
**Parent:** REQ-FE-003
**Size:** [XS]
**Details:** Remove the inline search `<div>` block (lines 511–522) from `ConsultantsPage.tsx`. Add `import { ConsultantFilterBar } from '@/components/consultants/ConsultantFilterBar'`. Render `<ConsultantFilterBar searchQuery={searchQuery} onSearchChange={...} onPageReset={() => setPage(1)} />`. Remove `Search` and `Input` imports from the top if no longer used elsewhere.

## [x] Replace inline leaderboard in BillingSummaryPage with RevenueLeaderboard
**Parent:** REQ-FE-005, REQ-FE-006, REQ-FE-007
**Size:** [S]
**Details:** Remove the inline leaderboard table JSX (the `<Card>` block with table at lines 83–90) from `BillingSummaryPage.tsx`. Remove the `leaderboard` useMemo and `TrendingUp` import if no longer used elsewhere. Add `import RevenueLeaderboard from '@/components/RevenueLeaderboard'`. Replace removed block with `<RevenueLeaderboard consultants={leaderboard} />`. Verify the `ConsultantBrief` interface (line 10) matches what RevenueLeaderboard expects.

## [x] Remove unused imports from ConsultantsPage after extraction
**Parent:** REQ-FE-001, REQ-FE-002, REQ-FE-003
**Size:** [XS]
**Details:** Audit `ConsultantsPage.tsx` imports after all extractions. Remove: `ArrowDown`, `ArrowUp`, `Eye`, `Pencil`, `Search`, `Trash2`, `X` from lucide-react if unused; `Input` from `@/components/ui/input` if unused; `Label` from `@/components/ui/label` if unused; `useMemo` from React if `tenureBuckets` was the last use (keep if still used). Verify the file compiles and renders correctly.
