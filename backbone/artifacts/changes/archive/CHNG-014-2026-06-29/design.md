# CHNG-014: i18n Completeness — Design

## Strategy
For each section in coeff's i18n files, compare against Javalin's. Identify keys present in Javalin but absent in coeff. Insert missing keys at the correct alphabetical position within each section.

## Key Diffing Method
1. Extract all keys from Javalin's `en.ts` → set J
2. Extract all keys from coeff's `en.ts` → set C
3. Missing = J \ C
4. For each missing key, insert into the correct section in both `en.ts` and `es.ts`

## Insertion Rules
- New keys go inside the existing section object, at the position matching Javalin's ordering.
- If the section doesn't exist in coeff (e.g., `setupWizard.*`), create the section at the same relative position as Javalin.
- Existing keys are never moved or modified.

## Section-by-Section Mapping

| Section | Position in coeff en.ts | Javalin end line | Insert strategy |
|---------|------------------------|------------------|----------------|
| consultants.* | lines 12-59 | line 75 | Add 14 keys after `consultants.coefMargin` |
| billing.* | lines 61-97 | line 132 | Add 11 keys after `billing.noPosition` |
| clients.* | lines 99-107 | line 143 | Add `revenueConcentration` |
| common.* | lines 124-145 | line 183 | Add `retry`, `amount` |
| auth.* | lines 147-166 | line 204 | Align autoLogout messages |
| simulator.* | lines 186-249 | line 271 | Add family situation keys, salary breakdown, etc. |
| config.* | lines 250-337 | line 375 | Add coefTab, card*, mngBonus*, dump backup keys |
| docs.* | lines 338-368 | line 406 | Add aboutFeatures, aboutTagline |
| report.* | NEW | lines 408-541 | Add benchmark, target, profitability sections |
| profitability.* | NEW | lines 554-557 | Add 4 keys |
| setupWizard.* | NEW | lines 559-580 | Add 24 keys |

## Decisions

### ADR-014-001: Manual insertion vs automated diff script
- **Decision:** Manual insertion of keys with section-by-section edits.
- **Rationale:** The key set is finite (214 additions). Automated diff scripts risk misaligned ordering or whitespace changes. Manual edits preserve formatting conventions exactly.
- **Type:** Two-way door.

### ADR-014-002: Preserve existing differing translations
- **Decision:** When a key exists in both files but with different values, keep coeff's existing value. Only add truly missing keys.
- **Rationale:** Some translations were intentionally customized (e.g., coeff's "Annual Delta" vs javalin's "Annual Target"). Overwriting would revert past decisions.
- **Type:** Two-way door.

## Traceability
| REQ-ID | File | Element |
|--------|------|---------|
| REQ-I18N-001 | frontend/src/i18n/en.ts | All 583 keys |
| REQ-I18N-002 | frontend/src/i18n/es.ts | All 583 keys |
| REQ-I18N-003 | Both files | Key ordering by section |
| REQ-I18N-004 | Both files | No existing key modification |
