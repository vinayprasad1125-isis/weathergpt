import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { WeatherService, AlertService } from '../../services/api';
import type { WeatherData, WeatherAlert, ForecastData } from '../../types/models';
import { Cloud, MapPin, Wind, Droplets, MessageSquare } from 'lucide-react';
import { Link } from 'react-router-dom';

function getWeatherIcon(_iconName: any) {
  // In a real app we'd map string to lucide icons or svg components.
  // For demo, we just return a cloud.
  return <Cloud className="w-12 h-12 text-blue-500" />;
}

export default function HomeView() {
  const { t } = useTranslation();
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [forecast, setForecast] = useState<ForecastData | null>(null);
  const [alerts, setAlerts] = useState<WeatherAlert[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadData() {
      try {
        const [w, f, a] = await Promise.all([
          WeatherService.getCurrentWeather(),
          WeatherService.getForecast(),
          AlertService.getAlerts()
        ]);
        setWeather(w);
        setForecast(f);
        setAlerts(a);
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    }
    loadData();
  }, []);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-full">
        <div className="animate-pulse flex flex-col items-center">
          <div className="w-16 h-16 bg-slate-200 dark:bg-navy-800 rounded-full mb-4"></div>
          <div className="w-32 h-4 bg-slate-200 dark:bg-navy-800 rounded"></div>
        </div>
      </div>
    );
  }

  if (!weather) return <div>Error loading data</div>;

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-24 relative">
      <div className="flex flex-col md:flex-row gap-6">
        {/* Weather Card */}
        <div className="flex-1 glass-effect rounded-3xl p-6 md:p-8 flex flex-col justify-between relative overflow-hidden bg-gradient-to-br from-blue-400 to-blue-600 text-white shadow-xl">
          <div className="flex justify-between items-start z-10">
            <div>
              <div className="flex items-center space-x-2 text-blue-100 mb-1">
                <MapPin className="w-4 h-4" />
                <span className="font-medium text-lg">{weather.location.city}</span>
              </div>
              <div className="text-blue-100 text-sm">{weather.condition}</div>
            </div>
            {getWeatherIcon(weather.icon)}
          </div>
          
          <div className="mt-8 z-10">
            <div className="text-6xl font-bold tracking-tighter">{weather.currentTemp}°</div>
            <div className="text-blue-100 mt-1">Feels like {weather.feelsLike}°</div>
          </div>

          <div className="mt-8 grid grid-cols-2 gap-4 z-10">
            <div className="flex items-center space-x-2 bg-white/20 rounded-xl p-3 backdrop-blur-sm">
              <Wind className="w-5 h-5 text-blue-100" />
              <div>
                <div className="text-xs text-blue-100 uppercase font-semibold">Wind</div>
                <div className="font-medium">{weather.windSpeed} km/h</div>
              </div>
            </div>
            <div className="flex items-center space-x-2 bg-white/20 rounded-xl p-3 backdrop-blur-sm">
              <Droplets className="w-5 h-5 text-blue-100" />
              <div>
                <div className="text-xs text-blue-100 uppercase font-semibold">Humidity</div>
                <div className="font-medium">{weather.humidity}%</div>
              </div>
            </div>
          </div>
        </div>

        {/* Alerts Summary */}
        <div className="w-full md:w-80 flex flex-col space-y-4">
          <h3 className="font-bold text-lg">{t('alerts')}</h3>
          {alerts.slice(0, 2).map((alert) => (
            <div key={alert.id} className="bg-white dark:bg-navy-900 rounded-2xl p-4 shadow-sm border-l-4 border-alert-extreme card-hover">
              <div className="flex items-start justify-between">
                <div className="font-semibold">{alert.type}</div>
                <span className="text-xs font-bold uppercase px-2 py-1 bg-alert-extreme/10 text-alert-extreme rounded-md">{alert.severity}</span>
              </div>
              <div className="text-sm text-slate-500 dark:text-slate-400 mt-2 line-clamp-2">{alert.description}</div>
            </div>
          ))}
          {alerts.length === 0 && (
            <div className="bg-white dark:bg-navy-900 rounded-2xl p-6 shadow-sm flex flex-col items-center text-center">
              <div className="w-12 h-12 bg-green-50 dark:bg-green-900/20 rounded-full flex items-center justify-center mb-3">
                <Cloud className="w-6 h-6 text-green-500" />
              </div>
              <div className="text-slate-500">{t('noActiveWarnings')}</div>
            </div>
          )}
        </div>
      </div>

      {/* Today's Forecast */}
      {forecast && (
        <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-lg">Today's Forecast</h3>
            <Link to="/forecast" className="text-primary-600 dark:text-primary-400 text-sm font-medium hover:underline">
              {t('more')}
            </Link>
          </div>
          <div className="flex overflow-x-auto pb-4 gap-4 snap-x">
            {forecast.hourly.map((hour, idx) => (
              <div key={idx} className="flex flex-col items-center flex-shrink-0 w-20 snap-center">
                <div className="text-sm text-slate-500 dark:text-slate-400 mb-2">{hour.time}</div>
                {getWeatherIcon(hour.icon)}
                <div className="font-bold mt-2">{hour.temp}°</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* FAB for Chat */}
      <Link 
        to="/chat" 
        className="fixed bottom-6 right-6 md:bottom-10 md:right-10 w-14 h-14 bg-primary-600 hover:bg-primary-700 text-white rounded-full flex items-center justify-center shadow-xl transition-transform hover:scale-105 z-50"
      >
        <MessageSquare className="w-6 h-6" />
      </Link>
    </div>
  );
}
