import { Route, Routes, Navigate } from 'react-router';
import { Layout1 } from '@/components/layouts/layout-1';
import ConsultantsPage from '@/pages/ConsultantsPage';
import BillingSummaryPage from '@/pages/BillingSummaryPage';
import ClientsPage from '@/pages/ClientsPage';
import FileImportPage from '@/pages/FileImportPage';

export function AppRoutingSetup() {
  return (
    <Routes>
      <Route element={<Layout1 />}>
        <Route path="/" element={<ConsultantsPage />} />
        <Route path="/billing" element={<BillingSummaryPage />} />
        <Route path="/clients" element={<ClientsPage />} />
        <Route path="/import" element={<FileImportPage />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}