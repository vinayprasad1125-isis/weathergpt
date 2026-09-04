import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AdvisoryService } from '../../services/api';
import type { Advisory } from '../../types/models';
import { Leaf, Plane, Anchor, Building, AlertTriangle, Info, MapPin, CloudRain, Thermometer } from 'lucide-react';
import { clsx } from 'clsx';

export default function AdvisoriesView() {
  const { t } = useTranslation();
  const [advisories, setAdvisories] = useState<Advisory[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    AdvisoryService.getAdvisories().then(a => {
      setAdvisories(a);
      setLoading(false);
    });
  }, []);

  const getCategoryConfig = (category: string) => {
    switch (category.toLowerCase()) {
      case 'agriculture': return { icon: Leaf, color: 'text-green-600', bg: 'bg-green-100 dark:bg-green-900/30' };
      case 'aviation': return { icon: Plane, color: 'text-blue-600', bg: 'bg-blue-100 dark:bg-blue-900/30' };
      case 'marine': return { icon: Anchor, color: 'text-teal-600', bg: 'bg-teal-100 dark:bg-teal-900/30' };
      case 'urban': return { icon: Building, color: 'text-purple-600', bg: 'bg-purple-100 dark:bg-purple-900/30' };
      case 'disaster': return { icon: AlertTriangle, color: 'text-red-600', bg: 'bg-red-100 dark:bg-red-900/30' };
      default: return { icon: Info, color: 'text-primary-600', bg: 'bg-primary-100 dark:bg-primary-900/30' };
    }
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-4 max-w-3xl mx-auto">
        <div className="h-40 bg-slate-200 dark:bg-navy-800 rounded-2xl"></div>
        <div className="h-40 bg-slate-200 dark:bg-navy-800 rounded-2xl"></div>
      </div>
    );
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-10">
      <h2 className="text-2xl font-bold mb-6">{t('advisories')}</h2>

      {advisories.map(advisory => {
        const config = getCategoryConfig(advisory.category);
        const Icon = config.icon;
        
        return (
          <div key={advisory.id} className="bg-white dark:bg-navy-900 rounded-2xl p-6 shadow-sm border border-slate-100 dark:border-navy-800 card-hover">
            <div className="flex items-start space-x-4">
              <div className={clsx("p-3 rounded-xl flex-shrink-0", config.bg)}>
                <Icon className={clsx("w-6 h-6", config.color)} />
              </div>
              <div className="flex-1">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-bold text-lg">{advisory.title}</h3>
                  <span className={clsx("text-xs font-semibold px-2 py-1 rounded-md", config.bg, config.color)}>
                    {advisory.category}
                  </span>
                </div>
                
                <div className="flex items-center text-sm text-slate-500 dark:text-slate-400 mb-4 space-x-4">
                  <span className="flex items-center"><MapPin className="w-4 h-4 mr-1" /> {advisory.location}</span>
                </div>

                <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed mb-4">
                  {advisory.details}
                </p>

                <div className="flex flex-wrap gap-3">
                  <div className="flex items-center space-x-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 bg-slate-50 dark:bg-navy-800 px-3 py-1.5 rounded-lg border border-slate-100 dark:border-navy-700">
                    <Thermometer className="w-3.5 h-3.5" />
                    <span>{advisory.tempRange}</span>
                  </div>
                  <div className="flex items-center space-x-1.5 text-xs font-medium text-slate-600 dark:text-slate-300 bg-slate-50 dark:bg-navy-800 px-3 py-1.5 rounded-lg border border-slate-100 dark:border-navy-700">
                    <CloudRain className="w-3.5 h-3.5 text-blue-500" />
                    <span>{advisory.rainProbability}% Rain Prob.</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
