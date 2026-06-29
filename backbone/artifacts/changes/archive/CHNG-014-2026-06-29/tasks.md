# CHNG-014: i18n Completeness — Tasks

## Task List

### [x] [M] T-001: Add missing consultants.* keys to en.ts and es.ts
Add 17 keys (vs listed 14 — actual count from diff): cardConsultores, cardClientes, cardCoef, active, withActiveConsultants, average, aboveAverage, belowAverage, abovePeerThreshold, threshold, cardTarifas, avgRate, status, profitability, qGoal, overGoal, behindGoal.
- **Files:** en.ts, es.ts
- **Verification:** 17 new keys in each file. `tsc --noEmit` passes.

### [x] [S] T-002: Add missing billing.* keys
Add 10 keys (actually missing — excludes bonusBreakdown, tenureBonus, quarterlyBonus, allYears, managerBonus which already existed): mom, totalConsultants, allTime, thisYear, periodLabelAll, periodLabelYear, showActive, showAll, leaderboard, leaderboardSearch.
- **Files:** en.ts, es.ts
- **Verification:** 10 new keys in each file.

### [x] [S] T-003: Add missing common.* keys
Add 2 keys: retry, amount.
- **Files:** en.ts, es.ts
- **Verification:** 2 new keys in each file.

### [x] [M] T-004: Add missing config.* section keys
Add 20 keys: coefTab, cardMultipliers, cardManagerBonus, cardSsBenefits, cardBonusPayouts, positionTariffAlertPct, positionTariffAlertPctHint, cardThresholds, mngBonusExcludedMonths, deductionChild, deductionAsc, deductionDis, backupCreated, restoreConfirmTitle, restoreConfirmMessage, restored, noBackups, pruneConfirmTitle, pruneConfirmMessage, pruned.
- **Files:** en.ts, es.ts
- **Verification:** 20 new keys in each file.

### [x] [S] T-005: Add missing simulator.* keys
Add 6 keys (others already existed from Phase 4): familySituation.single, familySituation.married, familySituation.other, saveToConsultantNamed, guardado, errorConexion.
- **Files:** en.ts, es.ts
- **Verification:** 6 new keys in each file.

### [x] [S] T-006: Add missing docs.* keys
Already present in coeff (aboutTagline, aboutFeatures existed). No additions needed.
- **Files:** en.ts, es.ts
- **Verification:** Doc section already at parity.

### [x] [M] T-007: Add report.* benchmark, target, profitability, perConsultant sections
Add ~125 keys covering full report section: title/subtitle, downloadAll/Section, csvExportCols, yearFilter/range/dateFrom/dateTo, section.*, col.*, coef.*, billing.*, client.*, roleAggregation.*, clientTimeline.*, perConsultant.*, forecast section keys, section.yoy, benchmarks.*, profitability.*, targets.*.
- **Files:** en.ts, es.ts
- **Verification:** Report section reaches full Javalin key parity.

### [x] [S] T-008: Add profitability.* section
Add 4 keys: profitable, atRisk, belowThreshold, insufficientData.
- **Files:** en.ts, es.ts
- **Verification:** New profitability section with 4 keys in each file.

### [x] [M] T-009: Add setupWizard.* section
Add 24 keys: welcome.title/description/selectLanguage/start, account.title/description, config.title/description/language/deltaAnnual/autoLogout, continue/finish/submitting, done.title/description/importCsv/Desc/restoreBackup/Desc/goDashboard/Desc.
- **Files:** en.ts, es.ts
- **Verification:** SetupWizard section matches Javalin exactly (24 keys).

### [x] [S] T-010: Add config.dump* backup keys
Add 7 keys (createDumpBackup, dumpBackupPassword, backupPasswordRequired already existed): dumpBackupPasswordConfirm, dumpBackupCreated, dumpBackupFailed, dumpRestorePassword, dumpRestorePasswordRequired, backupPasswordMismatch, passwordChangeBackupFail.
- **Files:** en.ts, es.ts
- **Verification:** 7 new keys in each file.

### [x] [XS] T-011: Verify total key count
Count keys in en.ts (target: 583) and es.ts (target: 583). Actual Javalin has 557 en / 556 es keys.
- **Files:** en.ts, es.ts
- **Verification:** en.ts has 589 keys (all 557 Javalin keys + 32 coeff-custom), es.ts has 588 (all 556 Javalin keys + 32 coeff-custom). TypeScript compiles. Production build succeeds.
