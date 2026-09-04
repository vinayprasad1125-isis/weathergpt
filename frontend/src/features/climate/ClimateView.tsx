import { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ClimateService } from '../../services/api';
import type { ClimateData } from '../../types/models';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, } from 'recharts';
import { TrendingUp, TrendingDown, Clock } from 'lucide-react';

export default function ClimateView() {
  const { t } = useTranslation();
  const [data, setData] = useState<ClimateData | null>(null);
  const [loading, setLoading] = useState(true);
  const [timeRange, setTimeRange] = useState<'50' | 'All'>('All');

  useEffect(() => {
    // In demo mode this just returns mockData, but we can also load the real JSON if we want to show 1901-2025.
    // For now we will use the mock data as requested, and expand it a bit to show a trend.
    fetch('/data/india_temperature_1901_2025.json')
      .then(r => r.json())
      .then(json => {
        // Mock API transformation
        const transformed: ClimateData = {
          labels: json.map((d: any) => d.YEAR.toString()),
          historicalTemp: json.map((d: any) => d.ANNUAL),
          historicalRainfall: [],
        };
        setData(transformed);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        ClimateService.getClimateTrends().then(d => {
          setData(d);
          setLoading(false);
        });
      });
  }, []);

  const chartData = useMemo(() => {
    if (!data) return [];
    
    let startIndex = 0;
    if (timeRange === '50' && data.labels.length > 50) {
      startIndex = data.labels.length - 50;
    }

    return data.labels.slice(startIndex).map((label, idx) => ({
      year: label,
      temp: data.historicalTemp[startIndex + idx]
    }));
  }, [data, timeRange]);

  const trend = useMemo(() => {
    if (!chartData || chartData.length < 2) return { slope: 0, direction: 'flat' };
    
    // Simple least squares
    const n = chartData.length;
    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (let i = 0; i < n; i++) {
      const x = i; // using index for x to prevent large numbers, slope remains same per year
      const y = chartData[i].temp;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }
    
    const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return {
      slope: slope,
      direction: slope > 0.005 ? 'up' : slope < -0.005 ? 'down' : 'flat'
    };
  }, [chartData]);

  if (loading) {
    return (
      <div className="animate-pulse space-y-6 max-w-4xl mx-auto">
        <div className="h-24 bg-slate-200 dark:bg-navy-800 rounded-3xl"></div>
        <div className="h-96 bg-slate-200 dark:bg-navy-800 rounded-3xl"></div>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-10">
      
      {/* Header and Controls */}
      <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-navy-800 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold">{t('climate')}</h2>
          <p className="text-slate-500 dark:text-slate-400">India Annual Mean Temperature</p>
        </div>
        
        <div className="flex bg-slate-100 dark:bg-navy-950 p-1 rounded-xl">
          <button 
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${timeRange === 'All' ? 'bg-white dark:bg-navy-800 shadow-sm text-primary-600' : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'}`}
            onClick={() => setTimeRange('All')}
          >
            Full Dataset
          </button>
          <button 
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${timeRange === '50' ? 'bg-white dark:bg-navy-800 shadow-sm text-primary-600' : 'text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'}`}
            onClick={() => setTimeRange('50')}
          >
            Last 50 Years
          </button>
        </div>
      </div>

      {/* Trend Summary */}
      <div className="bg-gradient-to-r from-slate-50 to-white dark:from-navy-900 dark:to-navy-800 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-navy-800 flex items-center space-x-4">
        <div className={`p-4 rounded-2xl ${trend.direction === 'up' ? 'bg-red-100 dark:bg-red-900/30 text-red-600' : trend.direction === 'down' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-600' : 'bg-slate-100 dark:bg-navy-800 text-slate-600'}`}>
          {trend.direction === 'up' ? <TrendingUp className="w-8 h-8" /> : trend.direction === 'down' ? <TrendingDown className="w-8 h-8" /> : <Clock className="w-8 h-8" />}
        </div>
        <div>
          <div className="text-sm font-semibold text-slate-500 uppercase tracking-wider">Observed Trend</div>
          <div className="text-2xl font-bold flex items-baseline space-x-2">
            <span>{trend.slope > 0 ? '+' : ''}{trend.slope.toFixed(3)}°C</span>
            <span className="text-sm text-slate-500 font-normal">/ year</span>
          </div>
        </div>
      </div>

      {/* Chart */}
      <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm border border-slate-100 dark:border-navy-800 h-[500px]">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 20, right: 30, left: 0, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" opacity={0.5} vertical={false} />
            <XAxis 
              dataKey="year" 
              stroke="#94a3b8" 
              fontSize={12} 
              tickLine={false} 
              axisLine={false} 
              tickMargin={10} 
            />
            <YAxis 
              domain={['auto', 'auto']} 
              stroke="#94a3b8" 
              fontSize={12} 
              tickLine={false} 
              axisLine={false}
              tickFormatter={(val) => `${val}°C`}
              tickMargin={10}
            />
            <RechartsTooltip 
              contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
              itemStyle={{ color: '#0ea5e9', fontWeight: 'bold' }}
              labelStyle={{ color: '#64748b', marginBottom: '4px' }}
              formatter={(value: any) => [`${value.toFixed(2)}°C`, 'Temperature']}
            />
            <Line 
              type="monotone" 
              dataKey="temp" 
              stroke="#0ea5e9" 
              strokeWidth={3}
              dot={false}
              activeDot={{ r: 6, fill: '#0ea5e9', stroke: '#fff', strokeWidth: 2 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
