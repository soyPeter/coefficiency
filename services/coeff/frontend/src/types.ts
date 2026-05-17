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
