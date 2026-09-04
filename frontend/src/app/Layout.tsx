import { useState } from 'react';
import { Outlet, NavLink, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Cloud, Home, Map as MapIcon, CloudRain, AlertTriangle, PlaneTakeoff, BarChart2, BookOpen, Settings, Menu, X, Bell } from 'lucide-react';
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export default function Layout() {
  const { t } = useTranslation();
  const location = useLocation();
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  const navItems = [
    { to: '/', icon: Home, label: t('home') },
    { to: '/map', icon: MapIcon, label: t('maps') },
    { to: '/forecast', icon: CloudRain, label: t('forecast') },
    { to: '/alerts', icon: AlertTriangle, label: t('alerts') },
    { to: '/aviation', icon: PlaneTakeoff, label: 'Aviation Weather' },
    { to: '/climate', icon: BarChart2, label: t('climate') },
    { to: '/advisories', icon: BookOpen, label: t('advisories') },
    { to: '/settings', icon: Settings, label: t('settings') },
  ];

  const closeMenu = () => setIsMobileMenuOpen(false);

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 dark:bg-navy-950 text-slate-800 dark:text-slate-100">
      {/* Mobile Sidebar Overlay */}
      {isMobileMenuOpen && (
        <div 
          className="fixed inset-0 z-40 bg-black/50 md:hidden"
          onClick={closeMenu}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-navy-900 border-r border-slate-200 dark:border-navy-800 transform transition-transform duration-200 ease-in-out md:relative md:translate-x-0 flex flex-col",
          isMobileMenuOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        <div className="p-6 flex items-center justify-between md:justify-start space-x-3">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-primary-500 rounded-xl flex items-center justify-center shadow-sm">
              <Cloud className="w-6 h-6 text-white" />
            </div>
            <span className="text-xl font-bold text-primary-600 dark:text-primary-400">WeatherGPT</span>
          </div>
          <button className="md:hidden p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-navy-800" onClick={closeMenu}>
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto px-4 py-2 space-y-1">
          {navItems.map((item) => {
            const isActive = location.pathname === item.to;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={closeMenu}
                className={cn(
                  "flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-colors",
                  isActive 
                    ? "bg-primary-50 text-primary-700 dark:bg-primary-500/10 dark:text-primary-400" 
                    : "text-slate-600 hover:bg-slate-50 dark:text-slate-400 dark:hover:bg-navy-800"
                )}
              >
                <item.icon className={cn("w-5 h-5 mr-3", isActive ? "text-primary-600 dark:text-primary-400" : "")} />
                {item.label}
              </NavLink>
            );
          })}
        </nav>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Header */}
        <header className="h-16 flex items-center justify-between px-4 sm:px-6 lg:px-8 bg-white/80 dark:bg-navy-900/80 backdrop-blur-md border-b border-slate-200 dark:border-navy-800 z-10">
          <button 
            className="md:hidden p-2 -ml-2 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-navy-800 rounded-lg"
            onClick={() => setIsMobileMenuOpen(true)}
          >
            <Menu className="w-6 h-6" />
          </button>
          
          <div className="flex-1" />
          
          <div className="flex items-center space-x-4">
            <button className="p-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 bg-slate-100 dark:bg-navy-800 rounded-full transition-colors relative">
              <Bell className="w-5 h-5" />
              <span className="absolute top-1.5 right-2 w-2 h-2 bg-alert-extreme rounded-full"></span>
            </button>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-6 lg:p-8 relative">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
