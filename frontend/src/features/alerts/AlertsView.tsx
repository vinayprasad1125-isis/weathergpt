import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AlertService } from '../../services/api';
import type { WeatherAlert } from '../../types/models';
import { AlertTriangle, Clock, MapPin, CheckCircle, Info } from 'lucide-react';
import { clsx } from 'clsx';

export default function AlertsView() {
  const { t } = useTranslation();
  const [alerts, setAlerts] = useState<WeatherAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedAlert, setSelectedAlert] = useState<WeatherAlert | null>(null);

  useEffect(() => {
    AlertService.getAlerts().then(a => {
      setAlerts(a);
      setLoading(false);
    });
  }, []);

  if (loading) {
    return (
      <div className="animate-pulse space-y-4 max-w-3xl mx-auto">
        <div className="h-32 bg-slate-200 dark:bg-navy-800 rounded-2xl"></div>
        <div className="h-32 bg-slate-200 dark:bg-navy-800 rounded-2xl"></div>
      </div>
    );
  }

  if (alerts.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-[60vh] text-center max-w-md mx-auto">
        <div className="w-20 h-20 bg-green-50 dark:bg-green-900/20 rounded-full flex items-center justify-center mb-6">
          <CheckCircle className="w-10 h-10 text-green-500" />
        </div>
        <h2 className="text-2xl font-bold mb-2">No Active Alerts</h2>
        <p className="text-slate-500 dark:text-slate-400">
          There are no severe weather warnings or alerts for your monitored areas at this time.
        </p>
      </div>
    );
  }

  const getSeverityStyle = (severity: string) => {
    switch (severity.toLowerCase()) {
      case 'extreme': return 'bg-alert-extreme/10 border-alert-extreme text-alert-extreme';
      case 'severe': return 'bg-alert-severe/10 border-alert-severe text-alert-severe';
      case 'moderate': return 'bg-alert-moderate/10 border-alert-moderate text-alert-moderate';
      default: return 'bg-alert-minor/10 border-alert-minor text-alert-minor';
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-10 relative">
      <h2 className="text-2xl font-bold mb-6">{t('alerts')}</h2>

      {alerts.map(alert => (
        <div 
          key={alert.id} 
          onClick={() => setSelectedAlert(alert)}
          className={clsx(
            "bg-white dark:bg-navy-900 rounded-2xl p-5 shadow-sm border-l-4 cursor-pointer card-hover",
            alert.severity.toLowerCase() === 'extreme' ? 'border-alert-extreme' :
            alert.severity.toLowerCase() === 'severe' ? 'border-alert-severe' :
            alert.severity.toLowerCase() === 'moderate' ? 'border-alert-moderate' : 'border-alert-minor'
          )}
        >
          <div className="flex justify-between items-start mb-3">
            <h3 className="font-bold text-lg">{alert.type}</h3>
            <span className={clsx("text-xs font-bold uppercase px-3 py-1 rounded-full", getSeverityStyle(alert.severity))}>
              {alert.severity}
            </span>
          </div>
          
          <div className="flex flex-col space-y-2 text-sm text-slate-600 dark:text-slate-400">
            <div className="flex items-center">
              <MapPin className="w-4 h-4 mr-2" />
              {alert.location}
            </div>
            <div className="flex items-center">
              <Clock className="w-4 h-4 mr-2" />
              {alert.time}
            </div>
          </div>
          
          <p className="mt-4 text-sm line-clamp-2">{alert.description}</p>
        </div>
      ))}

      {/* Modal for details */}
      {selectedAlert && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 md:p-8 max-w-lg w-full max-h-[90vh] overflow-y-auto shadow-2xl">
            <div className="flex justify-between items-start mb-6">
              <div className="flex items-center space-x-3">
                <AlertTriangle className={clsx(
                  "w-8 h-8",
                  selectedAlert.severity.toLowerCase() === 'extreme' ? 'text-alert-extreme' :
                  selectedAlert.severity.toLowerCase() === 'severe' ? 'text-alert-severe' :
                  selectedAlert.severity.toLowerCase() === 'moderate' ? 'text-alert-moderate' : 'text-alert-minor'
                )} />
                <h3 className="text-2xl font-bold">{selectedAlert.type}</h3>
              </div>
              <button 
                onClick={() => setSelectedAlert(null)}
                className="p-2 hover:bg-slate-100 dark:hover:bg-navy-800 rounded-full"
              >
                &times;
              </button>
            </div>

            <div className="space-y-6">
              <div className="flex items-center space-x-2 text-sm text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-navy-800 p-3 rounded-xl">
                <MapPin className="w-5 h-5 flex-shrink-0" />
                <span>{selectedAlert.location}</span>
              </div>
              <div className="flex items-center space-x-2 text-sm text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-navy-800 p-3 rounded-xl">
                <Clock className="w-5 h-5 flex-shrink-0" />
                <span>{selectedAlert.time}</span>
              </div>

              <div>
                <h4 className="font-semibold mb-2">Description</h4>
                <p className="text-slate-700 dark:text-slate-300 text-sm leading-relaxed">{selectedAlert.description}</p>
              </div>

              <div className="bg-blue-50 dark:bg-blue-900/20 p-4 rounded-xl border border-blue-100 dark:border-blue-800/50">
                <div className="flex items-center space-x-2 text-blue-800 dark:text-blue-300 font-semibold mb-2">
                  <Info className="w-5 h-5" />
                  <h4>Recommended Action</h4>
                </div>
                <p className="text-blue-900/80 dark:text-blue-200/80 text-sm">{selectedAlert.recommendedAction}</p>
              </div>

              <div className="text-xs text-center text-slate-400 pt-4 border-t border-slate-100 dark:border-navy-800">
                Source: {selectedAlert.source}
              </div>
            </div>
            
            <button 
              onClick={() => setSelectedAlert(null)}
              className="w-full mt-8 bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-semibold py-3 rounded-xl hover:opacity-90 transition-opacity"
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
