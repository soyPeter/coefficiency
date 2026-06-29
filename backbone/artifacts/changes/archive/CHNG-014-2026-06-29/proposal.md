# CHNG-014: Javalin Parity Phase 7 — i18n Completeness

## Overview
Add 214 missing i18n keys to both `en.ts` and `es.ts` to reach full parity with Javalin (583 keys). Coeff currently has ~369 keys. Missing keys span: billing bonus breakdown, consultant status/cards, report client fields, report benchmarks, profitability status, setup wizard, dump backup, and more.

## EARS Requirements

### REQ-I18N-001 (Ubiquitous)
The `en.ts` file SHALL contain all 583 keys present in Javalin's `en.ts`.

### REQ-I18N-002 (Ubiquitous)
The `es.ts` file SHALL contain all 583 keys with Spanish translations matching Javalin's `es.ts`.

### REQ-I18N-003 (Ubiquitous)
Missing keys SHALL be added in logical section batches (billing.*, clients.*, config.*, consultants.*, etc.) preserving the existing key ordering.

### REQ-I18N-004 (Ubiquitous)
Existing keys SHALL NOT be modified — only additions.

## Missing Key Sections (214 total)

| Section | Missing Count | Key Pattern |
|---------|--------------|-------------|
| consultants.* | ~14 | cardConsultores, cardClientes, cardCoef, active, withActiveConsultants, average, aboveAverage, belowAverage, abovePeerThreshold, threshold, cardTarifas, avgRate, status, profitability, qGoal, overGoal, behindGoal |
| billing.* | ~11 | mom, totalConsultants, allTime, thisYear, periodLabelAll, periodLabelYear, showActive, showAll, bonusBreakdown, tenureBonus, quarterlyBonus, leaderboardSearch, managerBonus, allYears |
| common.* | ~2 | retry, amount |
| config.* | ~20 | coefTab, positionTariffAlertPct/hint, cardMultipliers/ManagerBonus/SsBenefits/BonusPayouts/Thresholds, mngBonusStartDay/EndDay/hints, mngBonusExcludedMonths, deductionChild/Asc/Dis, tenureBonusAmount/Months/hints, quarterlyBonusAmount/hints, passwordChangeBackupFail, backupCreated/restored/confirmTitle/confirmMessage/noBackups, pruneConfirmTitle/Message/pruned, saveEngineParams, cardThresholds |
| docs.* | ~4 | aboutTagline, aboutFeatures (section) |
| simulator.* | ~17 | familySituation.single/married/other, otherIncomeSS, taxFreeRemuneration, salaryBreakdown, grossMonthly, netAnnual, monthlyIRPF, monthlySS, irpfRate, ssRate, saveToConsultantNamed, guardado, errorConexion, personalData, ascendants, dailyMealCard, annualBonus, bonusSchedule, annualChildSupport, annualTraining, benefitsEquipment, hasLaptop/HealthInsurance, monthlyExtraIT/Licenses, otherIncome (section) |
| report.* | ~63 | All benchmark keys, target keys, perConsultant grossSalary/netSalary, profitability section, section names, client financials, bonus breakdown section |
| auth.* | ~1 | reset-database related |
| profitability.* | ~5 | profitable, atRisk, belowThreshold, insufficientData |
| setupWizard.* | ~24 | All 24 keys |
| config.dump* | ~10 | createDumpBackup, dumpBackupPassword/Confirm/Created/Failed, dumpRestorePassword/RestoreRequired, passwordChangeBackupFail |

## Scope
- **In scope:** `frontend/src/i18n/en.ts` and `frontend/src/i18n/es.ts` — add keys only.
- **Out of scope:** Pages consuming new keys (already handled or separate task).

- **REQ-ARCHIVE:** Completed and archived.
- **REQ-CLOSE-001**: All tasks completed and change archived.
