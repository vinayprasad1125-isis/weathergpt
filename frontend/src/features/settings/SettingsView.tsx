import React, { useContext } from 'react';
import { useTranslation } from 'react-i18next';
import { ThemeContext } from '../../context/ThemeContext';
import { Moon, Sun, Globe, Bell, FileText, ExternalLink, ShieldCheck } from 'lucide-react';
import { clsx } from 'clsx';

const Section = ({ title, children }: { title: string, children: React.ReactNode }) => (
  <div className="mb-8">
    <h3 className="text-sm font-bold text-primary-600 dark:text-primary-400 uppercase tracking-wider mb-4 px-2">{title}</h3>
    <div className="bg-white dark:bg-navy-900 rounded-3xl shadow-sm border border-slate-100 dark:border-navy-800 overflow-hidden">
      {children}
    </div>
  </div>
);

const Item = ({ icon: Icon, title, subtitle, action, isLast = false }: any) => (
  <div className={clsx(
    "flex items-center justify-between p-4 sm:p-5",
    !isLast && "border-b border-slate-100 dark:border-navy-800"
  )}>
    <div className="flex items-center space-x-4">
      <div className="p-2.5 bg-slate-50 dark:bg-navy-800 rounded-xl">
        <Icon className="w-5 h-5 text-slate-600 dark:text-slate-400" />
      </div>
      <div>
        <div className="font-semibold">{title}</div>
        {subtitle && <div className="text-sm text-slate-500 dark:text-slate-400 mt-0.5">{subtitle}</div>}
      </div>
    </div>
    <div>{action}</div>
  </div>
);

export default function SettingsView() {
  const { t, i18n } = useTranslation();
  const { isDark, toggleTheme } = useContext(ThemeContext);

  const handleLanguageChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const newLang = e.target.value;
    i18n.changeLanguage(newLang);
    localStorage.setItem('language', newLang);
  };

  return (
    <div className="max-w-3xl mx-auto pb-10">
      <h2 className="text-3xl font-bold mb-8 px-2">{t('settings')}</h2>

      <Section title="General">
        <Item 
          icon={isDark ? Moon : Sun} 
          title="Dark Mode" 
          subtitle="Toggle application appearance"
          action={
            <button 
              onClick={toggleTheme}
              className={clsx(
                "relative inline-flex h-7 w-12 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-2 dark:focus:ring-offset-navy-950",
                isDark ? 'bg-primary-600' : 'bg-slate-200 dark:bg-navy-700'
              )}
            >
              <span className={clsx(
                "inline-block h-5 w-5 transform rounded-full bg-white transition-transform",
                isDark ? 'translate-x-6' : 'translate-x-1'
              )} />
            </button>
          }
        />
        <Item 
          icon={Globe} 
          title="Language" 
          subtitle="Select application language"
          isLast={true}
          action={
            <select 
              value={i18n.language} 
              onChange={handleLanguageChange}
              className="bg-slate-50 dark:bg-navy-800 border-none outline-none text-sm font-medium rounded-xl py-2 px-3 focus:ring-2 focus:ring-primary-500"
            >
              <option value="en">English</option>
              <option value="hi">हिन्दी (Hindi)</option>
              <option value="ta">தமிழ் (Tamil)</option>
            </select>
          }
        />
      </Section>

      <Section title="Notifications">
        <Item 
          icon={Bell} 
          title="Severe Alerts" 
          subtitle="Receive push notifications for severe weather"
          action={
            <button className="relative inline-flex h-7 w-12 items-center rounded-full bg-primary-600 transition-colors">
              <span className="inline-block h-5 w-5 transform rounded-full bg-white transition-transform translate-x-6" />
            </button>
          }
        />
        <Item 
          icon={FileText} 
          title="Daily Summary" 
          subtitle="Morning digest of the day's forecast"
          isLast={true}
          action={
            <button className="relative inline-flex h-7 w-12 items-center rounded-full bg-slate-200 dark:bg-navy-700 transition-colors">
              <span className="inline-block h-5 w-5 transform rounded-full bg-white transition-transform translate-x-1" />
            </button>
          }
        />
      </Section>

      <Section title="About">
        <Item 
          icon={ShieldCheck} 
          title="Privacy Policy" 
          action={<ExternalLink className="w-5 h-5 text-slate-400 cursor-pointer hover:text-primary-500" onClick={() => alert("Privacy Policy placeholder (Needs legal review)")} />}
        />
        <Item 
          icon={FileText} 
          title="Terms of Service" 
          isLast={true}
          action={<ExternalLink className="w-5 h-5 text-slate-400 cursor-pointer hover:text-primary-500" onClick={() => alert("Terms of Service placeholder (Needs legal review)")} />}
        />
      </Section>
      
      <div className="text-center text-sm text-slate-400 mt-12">
        <p>WeatherGPT Platform</p>
        <p className="mt-1">Version 2.0.0 (React Migration)</p>
      </div>
    </div>
  );
}
