import { useEffect, useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { I18nextProvider } from 'react-i18next';
import i18n from '../i18n/config';
import Layout from './Layout';
import HomeView from '../features/home/HomeView';
import MapView from '../features/map/MapView';
import ForecastView from '../features/forecast/ForecastView';
import AlertsView from '../features/alerts/AlertsView';
import AviationView from '../features/aviation/AviationView';
import ClimateView from '../features/climate/ClimateView';
import AdvisoriesView from '../features/advisories/AdvisoriesView';
import SettingsView from '../features/settings/SettingsView';
import ChatView from '../features/chat/ChatView';
import { ThemeContext } from '../context/ThemeContext';

function App() {
  const [isDark, setIsDark] = useState(() => {
    const saved = localStorage.getItem('theme');
    return saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches);
  });

  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [isDark]);

  useEffect(() => {
    const savedLang = localStorage.getItem('language');
    if (savedLang) {
      i18n.changeLanguage(savedLang);
    }
  }, []);

  const toggleTheme = () => setIsDark(!isDark);

  return (
    <I18nextProvider i18n={i18n}>
      <ThemeContext.Provider value={{ isDark, toggleTheme }}>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<Layout />}>
              <Route index element={<HomeView />} />
              <Route path="map" element={<MapView />} />
              <Route path="forecast" element={<ForecastView />} />
              <Route path="alerts" element={<AlertsView />} />
              <Route path="aviation" element={<AviationView />} />
              <Route path="climate" element={<ClimateView />} />
              <Route path="advisories" element={<AdvisoriesView />} />
              <Route path="settings" element={<SettingsView />} />
              <Route path="chat" element={<ChatView />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </ThemeContext.Provider>
    </I18nextProvider>
  );
}

export default App;
