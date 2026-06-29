import { HashRouter, Route, Routes } from 'react-router-dom';
import { Layout1 } from '@/components/layouts/layout-1';
import ConsultantsPage from '@/pages/ConsultantsPage';
import ConfigPage from '@/pages/ConfigPage';
import BillingSummaryPage from '@/pages/BillingSummaryPage';
import ClientsPage from '@/pages/ClientsPage';
import FileImportPage from '@/pages/FileImportPage';
import DocsPage from '@/pages/DocsPage';
import ReportsPage from '@/pages/ReportsPage';

export function AppRouting() {
  return (
    <HashRouter>
      <Routes>
        <Route element={<Layout1 />}>
          <Route path="/" element={<ConsultantsPage />} />
          <Route path="/billing" element={<BillingSummaryPage />} />
          <Route path="/consultants" element={<ConsultantsPage />} />
          <Route path="/clients" element={<ClientsPage />} />
          <Route path="/import" element={<FileImportPage />} />
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/config" element={<ConfigPage />} />
          <Route path="/docs" element={<DocsPage />} />
        </Route>
      </Routes>
    </HashRouter>
  );
}