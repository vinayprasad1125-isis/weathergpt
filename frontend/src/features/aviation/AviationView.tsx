import { useState } from 'react';
import { AviationService } from '../../services/api';
import { PlaneTakeoff, Search, Wind, Thermometer, Eye, Cloud } from 'lucide-react';


export default function AviationView() {
  const [icao, setIcao] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [metar, setMetar] = useState<any>(null);
  const [taf, setTaf] = useState<any>(null);

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    const code = icao.trim().toUpperCase();
    
    if (code.length !== 4) {
      setError('Please enter a valid 4-letter ICAO code (e.g. VOMM, VABB)');
      return;
    }

    setLoading(true);
    setError(null);
    setMetar(null);
    setTaf(null);

    try {
      const [m, t] = await Promise.all([
        AviationService.getMETAR(code),
        AviationService.getTAF(code)
      ]);
      setMetar(m);
      setTaf(t);
    } catch (err: any) {
      setError(err.message || 'Failed to fetch aviation data.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6 pb-10">
      <h2 className="text-2xl font-bold mb-6">Aviation Weather</h2>

      {/* Search Bar */}
      <form onSubmit={handleSearch} className="bg-white dark:bg-navy-900 rounded-2xl p-2 flex items-center shadow-sm border border-slate-200 dark:border-navy-800 focus-within:ring-2 focus-within:ring-primary-500 transition-all">
        <div className="p-3 text-slate-400">
          <PlaneTakeoff className="w-5 h-5" />
        </div>
        <input 
          type="text" 
          value={icao}
          onChange={e => { setIcao(e.target.value.toUpperCase()); setError(null); }}
          placeholder="Enter 4-letter ICAO code (e.g., VOMM)"
          className="flex-1 bg-transparent border-none outline-none text-slate-800 dark:text-slate-100 placeholder-slate-400 uppercase font-mono"
          maxLength={4}
        />
        <button 
          type="submit" 
          disabled={loading || icao.length !== 4}
          className="bg-primary-600 hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed text-white p-3 rounded-xl transition-colors flex items-center justify-center"
        >
          {loading ? (
            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
          ) : (
            <Search className="w-5 h-5" />
          )}
        </button>
      </form>

      {error && (
        <div className="bg-alert-extreme/10 text-alert-extreme p-4 rounded-xl text-sm font-medium border border-alert-extreme/20">
          {error}
        </div>
      )}

      {/* METAR Card */}
      {metar && (
        <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm border border-slate-200 dark:border-navy-800">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-navy-800 pb-4 mb-4">
            <h3 className="font-bold text-lg flex items-center">
              <span className="bg-blue-100 dark:bg-blue-900/30 text-blue-600 px-2 py-1 rounded-md text-xs mr-3 font-bold">METAR</span>
              Current Observation
            </h3>
            <span className="text-xs text-slate-500">{metar.observationTime}</span>
          </div>

          <div className="font-mono text-sm bg-slate-50 dark:bg-navy-950 p-4 rounded-xl mb-6 text-slate-700 dark:text-slate-300 border border-slate-100 dark:border-navy-800 leading-relaxed">
            {metar.rawText}
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="flex flex-col space-y-1">
              <span className="text-xs text-slate-500 flex items-center"><Thermometer className="w-3 h-3 mr-1"/> Temp/Dew</span>
              <span className="font-semibold">{metar.temperature}°C / {metar.dewpoint}°C</span>
            </div>
            <div className="flex flex-col space-y-1">
              <span className="text-xs text-slate-500 flex items-center"><Wind className="w-3 h-3 mr-1"/> Wind</span>
              <span className="font-semibold">{metar.wind}</span>
            </div>
            <div className="flex flex-col space-y-1">
              <span className="text-xs text-slate-500 flex items-center"><Eye className="w-3 h-3 mr-1"/> Visibility</span>
              <span className="font-semibold">{metar.visibility}</span>
            </div>
            <div className="flex flex-col space-y-1">
              <span className="text-xs text-slate-500 flex items-center"><Cloud className="w-3 h-3 mr-1"/> Clouds</span>
              <span className="font-semibold text-sm">{metar.clouds}</span>
            </div>
          </div>
        </div>
      )}

      {/* TAF Card */}
      {taf && (
        <div className="bg-white dark:bg-navy-900 rounded-3xl p-6 shadow-sm border border-slate-200 dark:border-navy-800">
          <div className="flex items-center justify-between border-b border-slate-100 dark:border-navy-800 pb-4 mb-4">
            <h3 className="font-bold text-lg flex items-center">
              <span className="bg-purple-100 dark:bg-purple-900/30 text-purple-600 px-2 py-1 rounded-md text-xs mr-3 font-bold">TAF</span>
              Terminal Aerodrome Forecast
            </h3>
            <span className="text-xs text-slate-500">Valid: {taf.validTime}</span>
          </div>

          <div className="font-mono text-sm bg-slate-50 dark:bg-navy-950 p-4 rounded-xl text-slate-700 dark:text-slate-300 border border-slate-100 dark:border-navy-800 leading-relaxed">
            {taf.rawText}
          </div>
        </div>
      )}

      {!metar && !error && !loading && (
        <div className="text-center text-slate-500 mt-10">
          <PlaneTakeoff className="w-12 h-12 mx-auto mb-4 text-slate-300 dark:text-slate-700" />
          <p>Search for an ICAO code to view METAR and TAF data.</p>
          <p className="text-sm mt-2">Demo codes: VOMM, VABB, VIDP, VOBL</p>
        </div>
      )}
    </div>
  );
}
