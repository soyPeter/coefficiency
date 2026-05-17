'use client';

import * as React from 'react';

interface LayoutState {
  sidebarCollapse: boolean;
  setSidebarCollapse: (open: boolean) => void;
}

const LayoutContext = React.createContext<LayoutState>({ sidebarCollapse: false, setSidebarCollapse: () => {} });

export function LayoutProvider({ children }: { children: React.ReactNode }) {
  const [sidebarCollapse, setSidebarCollapse] = React.useState(false);
  return (
    <LayoutContext.Provider value={{ sidebarCollapse, setSidebarCollapse }}>
      {children}
    </LayoutContext.Provider>
  );
}

export function useLayout() {
  return React.useContext(LayoutContext);
}
