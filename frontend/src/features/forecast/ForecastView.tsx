import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { WeatherService } from '../../services/api';
import type { ForecastData } from '../../types/models';
import { Cloud, CloudRain, CloudLightning, Sun, Droplets } from 'lucide-react';

function getWeatherIcon(iconName: string) {
  switch (iconName) {
    case 'cloud-sun': return <Cloud className="w-8 h-8 text-blue-400" />;
    case 'cloud-rain': return <CloudRain className="w-8 h-8 text-blue-500" />;
    case 'cloud-lightning': return <CloudLightning className="w-8 h-8 text-indigo-500" />;
    case 'cloud': return <Cloud className="w-8 h-8 text-slate-400" />;
    default: return <Sun className="w-8 h-8 text-amber-500" />;
  }
}

export default function ForecastView() {
  const { t } = useTranslation();
  const [forecast, setForecast] = useState<ForecastData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    WeatherService.getForecast().then(f => {
      setForecast(f);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="animate-pulse space-y-6 max-w-3xl mx-auto">
        <div className="h-40 bg-slate-200 dark:bg-navy-800 rounded-3xl"></div>
        <div className="space-y-4">
          {[1,2,3].map(i => <div key={i} className="h-20 bg-slate-200 dark:bg-navy-800 rounded-2xl"></div>)}
        </div>
      </div>
    );
  }

  if (!forecast) return <div>Error</div>;

  return (
    <div className="max-w-3xl mx-auto space-y-8 pb-10">
      
      {/* Hourly */}
      <section>
        <h2 className="text-xl font-bold mb-4">{t('forecast')} (Hourly)</h2>
        <div className="flex overflow-x-auto gap-4 pb-4 snap-x">
          {forecast.hourly.map((hour, idx) => (
            <div key={idx} className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm flex flex-col items-center flex-shrink-0 w-28 snap-center card-hover border border-slate-100 dark:border-navy-800">
              <div className="text-sm font-medium text-slate-500 dark:text-slate-400 mb-3">{hour.time}</div>
              {getWeatherIcon(hour.icon)}
              <div className="font-bold text-xl mt-3">{hour.temp}°</div>
              <div className="flex items-center text-xs text-blue-500 mt-2 font-medium">
                <Droplets className="w-3 h-3 mr-1" />
                {hour.precipitationProb}%
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Daily */}
      <section>
        <h2 className="text-xl font-bold mb-4">7-Day Forecast</h2>
        <div className="space-y-3">
          {forecast.daily.map((day, idx) => (
            <div key={idx} className="bg-white dark:bg-navy-900 rounded-2xl p-4 sm:p-6 shadow-sm flex items-center justify-between border border-slate-100 dark:border-navy-800 hover:border-blue-500/30 transition-colors">
              <div className="flex-1">
                <div className="font-bold text-lg">{day.day}</div>
                <div className="text-sm text-slate-500">{day.date}</div>
              </div>
              
              <div className="flex-[2] flex items-center justify-center space-x-3">
                {getWeatherIcon(day.icon)}
                <span className="hidden sm:inline text-sm font-medium text-slate-600 dark:text-slate-300 w-32 text-center">
                  {day.condition}
                </span>
              </div>

              <div className="flex-1 flex justify-end items-center space-x-4">
                <div className="flex items-center text-xs text-blue-500 font-medium w-12 justify-end">
                  {day.precipitationProb > 0 && (
                    <>
                      <Droplets className="w-3 h-3 mr-1" />
                      {day.precipitationProb}%
                    </>
                  )}
                </div>
                <div className="text-right font-bold w-20">
                  <span className="text-slate-900 dark:text-white">{day.maxTemp}°</span>
                  <span className="text-slate-400 dark:text-slate-500 ml-2">{day.minTemp}°</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
