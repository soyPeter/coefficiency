export interface Consultant {
  id: number;
  name: string;
  client: string;
  position: string;
  coef: number;
  tariff: number;
  money: number;
  startDate: string;
  daysInRole: number;
  endDate?: string;
  fees: number;
  coefPercentage: number;
  coefMargin: number;
  managerBonus: number;
  simulationInputs?: string;
  profitabilityStatus?: 'PROFITABLE' | 'AT_RISK' | 'BELOW_THRESHOLD' | 'INSUFFICIENT_DATA';
  grossMonthlySalary: number;
  netMonthlySalary: number;
  netAnnualSalary: number;
  monthlySs: number;
  monthlyIrpf: number;
  irpfRate: number;
  ssRate: number;
  coefProjection?: string;
}

export interface CreateConsultantRequest {
  name: string;
  client: string;
  position: string;
  coef: number;
  tariff: number;
  startDate: string;
  endDate?: string;
  fees?: number;
  coefPercentage?: number;
  coefMargin?: number;
  managerBonus?: number;
}

export interface BillingSummary {
  daily: number;
  monthly: number;
  annual: number;
  consultantCount: number;
  activeCount: number;
  hires: number;
  terminations: number;
  delta: number;
  totalFees: number;
  avgCoefPct: number;
  totalCoefMargin: number;
  totalManagerBonus: number;
  expectedTerminations: number;
  expectedHires: number;
  coefDaysMonth: number;
  coefDaysYear: number;
}

export interface ClientSummary {
  client: string;
  positionCount: number;
}

export interface DocData {
  endpoints: { method: string; path: string; description: string; requestBody: string; responseBody: string }[];
  entities: { name: string; fields: { name: string; type: string; description: string }[] }[];
  config: { key: string; value: string; description: string }[];
  csvFormat: { columns: string[]; example: string };
}

export interface ImportResult {
  success: boolean;
  count: number;
  message: string;
}

// Report types
export interface ReportSection {
  section: string;
  data: any;
}

export interface ProfitabilityRow {
  month: string;
  marginPct: number;
  totalFees: number;
  avgCoefPct: number;
}

export interface TargetsResponse {
  targetRevenue: number;
  actualRevenue: number;
  targetMarginPct: number;
  actualMarginPct: number;
}

export interface ClientTimelineRow {
  month: string;
  fees: number;
  margin: number;
  activeConsultants: number;
}

export interface RoleAggregationRow {
  role: string;
  consultantCount: number;
  totalDaily: number;
  avgCoefPct: number;
  totalMargin: number;
  peerCount: number | null;
  p25: number | null;
  p50: number | null;
  p75: number | null;
}

export interface PerConsultantRow {
  id: number;
  name: string;
  client: string;
  position: string;
  tariff: number;
  fees: number;
  coefMargin: number;
  managerBonus: number;
}

export interface ForecastResponse {
  currentDailyBilling: number;
  ytdWorkingDays: number;
  ytdBilling: number;
  ytdGrowthPct: number | null;
  remainingWorkingDays: number;
  projectedRemaining: number;
  avgGrowthRatePct: number;
  projectedTotal: number;
  currentYear: number;
}

export interface YoyRow {
  year: number;
  daily: number;
  monthly: number;
  annual: number;
  headcount: number;
  hires: number;
  terminations: number;
  avgCoefPct: number;
  totalManagerBonus: number;
  delta: number | null;
  deltaPct: number | null;
}

export interface BenchmarkRow {
  role: string;
  p25: number;
  p50: number;
  p75: number;
  peerCount: number;
}

// REQ-BBD-001
export interface BonusBreakdownRow {
  id: number;
  year: number;
  month: string;
  managerBonus: number;
  tenureCount: number;
  tenureAmount: number;
  projectedTenureCount: number;
  projectedTenureAmount: number;
  quarterlyCount: number;
  quarterlyAmount: number;
  totalBonus: number;
}

// REQ-MOM-FRONT-001
export interface MomBillingRow {
  month: string;
  dailyBilling: number;
  workingDays: number;
  monthlyBilling: number;
  billingDelta: number | null;
  momGrowthPct: number | null;
  projected: boolean;
}

export interface MomBillingResponse {
  year: number;
  rows: MomBillingRow[];
}
