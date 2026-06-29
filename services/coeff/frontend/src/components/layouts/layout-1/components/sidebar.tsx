'use client';

import * as React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LogOut, ChevronFirst, Users, TrendingUp, Building, Upload, BookOpen, Settings, BarChart3 } from 'lucide-react';
import { useIntl } from 'react-intl';
import { cn } from '@/lib/utils';
import { useLayout } from './context';
import { Button } from '@/components/ui/button';
import { LanguageSwitcher } from '@/components/LanguageSwitcher';
import { clearToken } from '@/pages/LoginPage';

const NAV = [
  { label: 'menu.consultants', path: '/consultants', icon: Users },
  { label: 'menu.billing', path: '/billing', icon: TrendingUp },
  { label: 'menu.clients', path: '/clients', icon: Building },
  { label: 'menu.reports', path: '/reports', icon: BarChart3 },
  { label: 'menu.import', path: '/import', icon: Upload },
  { label: 'menu.config', path: '/config', icon: Settings },
  { label: 'menu.docs', path: '/docs', icon: BookOpen },
];

export function Sidebar() {
  const { sidebarCollapse, setSidebarCollapse } = useLayout();
  const { pathname } = useLocation();
  const intl = useIntl();

  const handleLogout = () => {
    navigator.sendBeacon('/api/auth/logout');
    clearToken();
    window.location.reload();
  };

  return (
    <aside className={cn(
      'fixed left-0 top-0 z-20 flex flex-col bg-sidebar text-sidebar-foreground border-r border-sidebar-border h-screen shadow-sm shrink-0',
      sidebarCollapse ? 'w-16' : 'w-64',
    )}>
      <div className={cn('flex items-center h-14 border-b border-sidebar-border shrink-0 transition-all', sidebarCollapse ? 'justify-center px-2' : 'justify-between px-4')}>
        <Link to="/" className={cn('font-bold text-lg tracking-wider', sidebarCollapse && 'hidden')}>
          BITNOMIO
        </Link>
        <Button variant="ghost" size="icon" onClick={() => setSidebarCollapse(!sidebarCollapse)} className="text-sidebar-foreground hover:text-sidebar-primary">
          <ChevronFirst className={cn('size-4 transition-transform', sidebarCollapse && 'rotate-180')} />
        </Button>
      </div>

      <nav className="flex-1 overflow-auto py-2 px-2 space-y-1">
        {NAV.map(item => {
          const active = pathname === '/' && item.path === '/consultants' ? true : pathname.startsWith(item.path) && item.path !== '/';
          return (
            <Link key={item.path} to={item.path}
              className={cn(
                'flex items-center gap-3 rounded-md transition-colors',
                active ? 'bg-sidebar-primary/10 text-sidebar-primary font-medium' : 'text-sidebar-foreground/70 hover:bg-sidebar-accent hover:text-sidebar-foreground',
                sidebarCollapse ? 'justify-center px-2 h-10' : 'px-3 py-2',
              )}
              title={sidebarCollapse ? intl.formatMessage({ id: item.label }) : undefined}
            >
              <item.icon className="size-5 shrink-0" />
              {!sidebarCollapse && <span className="text-sm">{intl.formatMessage({ id: item.label })}</span>}
            </Link>
          );
        })}
      </nav>

      <div className={cn('shrink-0 border-t border-sidebar-border space-y-1', sidebarCollapse ? 'px-2 py-3' : 'px-3 py-3')}>
        <LanguageSwitcher />
        {!sidebarCollapse && (
          <Button variant="ghost" size="sm" className="w-full justify-start text-xs text-sidebar-foreground/60" onClick={handleLogout}>
            <LogOut className="size-3.5 mr-2" />
            {intl.formatMessage({ id: 'auth.logout' })}
          </Button>
        )}
      </div>
    </aside>
  );
}
