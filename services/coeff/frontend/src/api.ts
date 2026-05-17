import type { Consultant, CreateConsultantRequest, BillingSummary, ClientSummary, ImportResult } from '@/types';

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

export async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${BASE}${url}`, {
    headers,
    ...options,
  });

  if (res.status === 401 || res.status === 503) {
    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    throw new AuthError();
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

  if (res.status === 401 || res.status === 503) {
    window.dispatchEvent(new CustomEvent('auth:unauthorized'));
    throw new AuthError();
  }

  return res.json();
}
