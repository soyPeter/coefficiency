# Traceability — CHNG-014: Javalin Parity Phase 7: i18n Completeness

## Implementation Summary

Added all 200 missing i18n keys to `services/coeff/frontend/src/i18n/en.ts` and `services/coeff/frontend/src/i18n/es.ts` to reach full key parity with Javalin reference project. 32 extra keys remain (flat key paths unique to coeff — intentional customizations). TypeScript compiles cleanly, production build succeeds.

## File Map

| REQ-ID | Files | Status |
|--------|-------|--------|
| REQ-I18N-001 | `services/coeff/frontend/src/i18n/en.ts` | All 557 Javalin keys present + 32 coeff-custom keys (589 total) |
| REQ-I18N-002 | `services/coeff/frontend/src/i18n/es.ts` | All 556 Javalin keys present + 32 coeff-custom keys (588 total) |
| REQ-I18N-003 | Both files | Keys added in logical section batches preserving Javalin ordering |
| REQ-I18N-004 | Both files | No existing keys modified — verified by diff |

## Sections Added/Extended

| Section | Keys Added (en) | Keys Added (es) | Description |
|---------|----------------|-----------------|-------------|
| consultants.* | 17 | 17 | cardConsultores, cardClientes, cardCoef, active, withActiveConsultants, average, aboveAverage, belowAverage, abovePeerThreshold, threshold, cardTarifas, avgRate, status, profitability, qGoal, overGoal, behindGoal |
| billing.* | 10 | 10 | mom, totalConsultants, allTime, thisYear, periodLabelAll, periodLabelYear, showActive, showAll, leaderboard, leaderboardSearch |
| clients.* | 1 | 1 | revenueConcentration |
| common.* | 2 | 2 | retry, amount |
| simulator.* | 6 | 6 | familySituation.single/married/other, saveToConsultantNamed, guardado, errorConexion |
| config.* | 20 | 20 | coefTab, cardMultipliers, cardManagerBonus, cardSsBenefits, cardBonusPayouts, positionTariffAlertPct/hint, cardThresholds, mngBonusExcludedMonths, deductionChild/Asc/Dis, backupCreated, restoreConfirmTitle/Message, restored, noBackups, pruneConfirmTitle/Message, pruned |
| config.dump* | 7 | 7 | dumpBackupPasswordConfirm, dumpBackupCreated, dumpBackupFailed, dumpRestorePassword, dumpRestorePasswordRequired, backupPasswordMismatch, passwordChangeBackupFail |
| report.* | ~125 | ~125 | Full report section: title, subtitle, downloadAll/Section, csvExportCols, yearFilter/range/dateFrom/dateTo, section.* (consultants, coef, billing, clients, bonuses, roleAggregation, clientTimeline, perConsultant, forecast, yoy, benchmarks, profitability, targets), col.*, coef.*, billing.*, client.*, roleAggregation.*, clientTimeline.*, perConsultant.*, benchmarks.*, profitability.*, targets.* |
| profitability.* | 4 | 4 | profitable, atRisk, belowThreshold, insufficientData |
| setupWizard.* | 24 | 24 | welcome.title/description/selectLanguage/start, account.title/description, config.title/description/language/deltaAnnual/autoLogout, continue/finish/submitting, done.title/description/importCsv/Desc/restoreBackup/Desc/goDashboard/Desc |

## Verification

- **Missing EN keys:** 0 (of 557 Javalin keys)
- **Missing ES keys:** 0 (of 556 Javalin keys)
- **Extra keys (intentional):** 32 per file (flat key paths unique to coeff)
- **TypeScript:** `tsc --noEmit` passes
- **Build:** `npm run build` passes (2553 modules transformed)
