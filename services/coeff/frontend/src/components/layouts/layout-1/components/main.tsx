'use client';

import * as React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './sidebar';
import { useLayout } from './context';

export function Main() {
  const { sidebarCollapse } = useLayout();
  return (
    <div className="min-h-screen w-full bg-background">
      <Sidebar />
      <main className="w-full min-h-screen" style={{ paddingLeft: sidebarCollapse ? '4rem' : '16rem' }}>
        <Outlet />
      </main>
    </div>
  );
}
