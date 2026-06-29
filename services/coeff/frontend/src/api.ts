import type {
  Consultant, CreateConsultantRequest, BillingSummary, ClientSummary, ImportResult,
  ReportSection, ProfitabilityRow, TargetsResponse, ClientTimelineRow,
  RoleAggregationRow, PerConsultantRow, ForecastResponse, YoyRow, BenchmarkRow,
  MomBillingResponse, BonusBreakdownRow
} from '@/types';

const BASE = '/api';

export function authHeaders(): Record<string, string> {
  const token = localStorage.getItem('token');
  return token ? { 'Authorization': `Bearer ${token}` } : {};
}

export class AuthError extends Error {
  constructor() {
    super('Unauthorized');
    this.name = 'AuthError';
  }
}

export class ServiceUnavailableError extends Error {
  constructor() {
    super('Service Unavailable');
    this.name = 'ServiceUnavailableError';
  }
}

export async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE}${url}`, {
    headers,
    ...options,
  });

  if (res.status === 401) {
    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    throw new AuthError();
  }

  if (res.status === 503) {
    throw new ServiceUnavailableError();
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: res.statusText }));
    throw new Error(err.error || res.statusText);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export async function fetchConsultants(): Promise<Consultant[]> {
  const res = await request<{items: Consultant[]}>('/consultants');
  return res.items || [];
}

export async function fetchConsultant(id: number): Promise<Consultant> {
  return request<Consultant>(`/consultants/${id}`);
}

export async function createConsultant(data: CreateConsultantRequest): Promise<Consultant> {
  return request<Consultant>('/consultants', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function updateConsultant(id: number, data: CreateConsultantRequest): Promise<Consultant> {
  return request<Consultant>(`/consultants/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export interface CoefUpdateRequest {
  fees: number;
  coefPercentage: number;
  coefMargin: number;
  managerBonus: number;
}

export async function updateConsultantCoef(id: number, data: CoefUpdateRequest): Promise<Consultant> {
  return request<Consultant>(`/consultants/${id}/coef`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export async function deleteConsultant(id: number): Promise<void> {
  return request<void>(`/consultants/${id}`, { method: 'DELETE' });
}

export async function fetchBillingSummary(): Promise<BillingSummary> {
  return request<BillingSummary>('/billing/summary');
}

export async function fetchBillingMonthly(): Promise<any[]> {
  return request<any[]>('/billing/monthly');
}

// REQ-MOM-FRONT-001
export async function fetchMomBilling(year?: number): Promise<MomBillingResponse> {
  const query = year ? `?year=${year}` : '';
  return request<MomBillingResponse>(`/billing/mom${query}`);
}

// REQ-BBD-001, REQ-BBD-003
export async function fetchBonusBreakdown(year?: number): Promise<BonusBreakdownRow[]> {
  const query = year ? `?year=${year}` : '';
  return request<BonusBreakdownRow[]>(`/billing/bonus-breakdown${query}`);
}

// REQ-BBD-002
export async function refreshBonusBreakdown(): Promise<void> {
  await request<void>('/billing/bonus-breakdown/refresh', { method: 'POST' });
}

export async function fetchClientSummaries(): Promise<ClientSummary[]> {
  return request<ClientSummary[]>('/clients');
}

export async function fetchClientFinancial(): Promise<any[]> {
  return request<any[]>('/clients/financial');
}

export async function uploadFile(file: File): Promise<ImportResult> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {};
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const formData = new FormData();
  formData.append('file', file);
  const res = await fetch(`${BASE}/files/upload`, {
    method: 'POST',
    headers,
    body: formData,
  });

  if (res.status === 401) {
    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    throw new AuthError();
  }

  if (res.status === 503) {
    throw new ServiceUnavailableError();
  }

  return res.json();
}

// Report API
export async function fetchReportYears(): Promise<number[]> {
  return request<number[]>('/report/years');
}

export async function fetchReport(year?: number, from?: string, to?: string): Promise<ReportSection[]> {
  const params = new URLSearchParams();
  if (year) params.set('year', String(year));
  if (from) params.set('from', from);
  if (to) params.set('to', to);
  const qs = params.toString();
  return request<ReportSection[]>(`/report${qs ? '?' + qs : ''}`);
}

export async function fetchProfitability(year?: number, from?: string, to?: string): Promise<ProfitabilityRow[]> {
  const params = new URLSearchParams();
  if (year) params.set('year', String(year));
  if (from) params.set('from', from);
  if (to) params.set('to', to);
  const qs = params.toString();
  return request<ProfitabilityRow[]>(`/report/profitability${qs ? '?' + qs : ''}`);
}

export async function fetchTargets(year?: number): Promise<TargetsResponse> {
  const qs = year ? `?year=${year}` : '';
  return request<TargetsResponse>(`/report/targets${qs}`);
}

export async function fetchClientTimeline(client: string, year?: number): Promise<ClientTimelineRow[]> {
  const params = new URLSearchParams({ client });
  if (year) params.set('year', String(year));
  return request<ClientTimelineRow[]>(`/report/client-timeline?${params}`);
}

export async function fetchReportClients(): Promise<string[]> {
  return request<string[]>('/report/clients');
}

export async function fetchRoleAggregation(): Promise<RoleAggregationRow[]> {
  return request<RoleAggregationRow[]>('/report/role-aggregation');
}

export async function fetchPerConsultant(search?: string, sortBy?: string, sortDir?: string): Promise<PerConsultantRow[]> {
  const params = new URLSearchParams();
  if (search) params.set('search', search);
  if (sortBy) params.set('sortBy', sortBy);
  if (sortDir) params.set('sortDir', sortDir);
  const qs = params.toString();
  return request<PerConsultantRow[]>(`/report/per-consultant${qs ? '?' + qs : ''}`);
}

export async function fetchForecast(): Promise<ForecastResponse> {
  return request<ForecastResponse>('/report/forecast');
}

export async function fetchYoy(): Promise<YoyRow[]> {
  return request<YoyRow[]>('/report/yoy');
}

export async function fetchBenchmarks(): Promise<BenchmarkRow[]> {
  return request<BenchmarkRow[]>('/report/benchmarks');
}

// Admin API
export interface BackupFile { filename: string; size: number; createdAt: string; }

export async function changePassword(oldPassword: string, newPassword: string): Promise<void> {
  await request<void>('/auth/password', {
    method: 'POST',
    body: JSON.stringify({ oldPassword, newPassword }),
  });
}

export async function createBackup(): Promise<BackupFile> {
  return request<BackupFile>('/admin/backup', { method: 'POST' });
}

export async function listBackups(type?: string): Promise<BackupFile[]> {
  const qs = type ? `?type=${type}` : '';
  return request<BackupFile[]>(`/admin/backups${qs}`);
}

export async function restoreBackup(filename: string): Promise<void> {
  await request<void>(`/admin/backups/${encodeURIComponent(filename)}/restore`, { method: 'POST' });
}

export async function createDumpBackup(password: string): Promise<BackupFile> {
  return request<BackupFile>('/admin/backup-dump', {
    method: 'POST',
    body: JSON.stringify({ password }),
  });
}

export async function restoreDumpBackup(filename: string, password: string): Promise<void> {
  await request<void>(`/admin/backups/dump/${encodeURIComponent(filename)}/restore`, {
    method: 'POST',
    body: JSON.stringify({ password }),
  });
}

export async function pruneDatabase(): Promise<void> {
  await request<void>('/admin/prune', { method: 'POST' });
}
