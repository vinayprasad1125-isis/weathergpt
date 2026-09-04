import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, GeoJSON, } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

import { Layers, Locate } from 'lucide-react';

const MAP_LAYERS = [
  'Base Map',
  'Temperature',
  'Rainfall / Precipitation',
  'Weather Radar',
  'Cyclone Tracking',
  'Flood Risk',
  'Wind'
];

export default function MapView() {
  
  const [geoData, setGeoData] = useState<any>(null);
  const [activeLayer, setActiveLayer] = useState(MAP_LAYERS[1]); // Temperature by default
  const [selectedState, setSelectedState] = useState<string>('Tamil Nadu');

  useEffect(() => {
    fetch('/data/india_states.geojson')
      .then(res => res.json())
      .then(data => setGeoData(data))
      .catch(console.error);
  }, []);

  const getStyle = (feature: any) => {
    // Generate deterministic colors based on state name for demo purposes
    const stateName = feature.properties.NAME_1;
    let color = '#3388ff';
    let weight = 1;
    let fillOpacity = 0.2;

    if (activeLayer === 'Temperature') {
      const isHot = stateName.length % 2 === 0;
      color = isHot ? '#ef4444' : '#f59e0b';
      fillOpacity = 0.5;
    } else if (activeLayer === 'Rainfall / Precipitation') {
      const isWet = stateName.includes('a');
      color = isWet ? '#3b82f6' : '#93c5fd';
      fillOpacity = 0.5;
    }

    if (stateName === selectedState) {
      weight = 3;
      color = '#000000';
    }

    return {
      color,
      weight,
      fillOpacity,
    };
  };

  const onEachFeature = (feature: any, layer: any) => {
    layer.on({
      click: () => {
        setSelectedState(feature.properties.NAME_1);
      }
    });
    layer.bindTooltip(feature.properties.NAME_1, { sticky: true });
  };

  return (
    <div className="h-full w-full relative flex flex-col rounded-3xl overflow-hidden shadow-sm border border-slate-200 dark:border-navy-800">
      
      {/* Top Controls Overlay */}
      <div className="absolute top-4 left-4 right-4 z-[400] flex flex-col sm:flex-row justify-between gap-4 pointer-events-none">
        
        {/* Layer Selector */}
        <div className="pointer-events-auto bg-white/90 dark:bg-navy-900/90 backdrop-blur-md rounded-xl shadow-lg p-2 flex flex-col max-w-xs">
          <div className="flex items-center space-x-2 px-2 pb-2 mb-2 border-b border-slate-200 dark:border-navy-700">
            <Layers className="w-4 h-4" />
            <span className="font-semibold text-sm">Layers</span>
          </div>
          <select 
            className="bg-transparent text-sm focus:outline-none cursor-pointer"
            value={activeLayer}
            onChange={(e) => setActiveLayer(e.target.value)}
          >
            {MAP_LAYERS.map(layer => (
              <option key={layer} value={layer}>{layer}</option>
            ))}
          </select>
        </div>

        {/* Selected Location Info Bubble */}
        <div className="pointer-events-auto bg-white/90 dark:bg-navy-900/90 backdrop-blur-md rounded-xl shadow-lg p-4 flex flex-col items-end">
          <div className="font-bold text-lg">{selectedState}</div>
          <div className="text-sm text-slate-500">
            {activeLayer === 'Temperature' ? '31°C' : 'Normal Conditions'}
          </div>
        </div>
      </div>

      <MapContainer {...({ center: [20.5937, 78.9629], zoom: 5, style: { height: '100%', width: '100%', zIndex: 10 }, zoomControl: false } as any)}>
        <TileLayer {...({ attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors', url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'} as any)} />
        {geoData && (
          <GeoJSON {...({ data: geoData, style: getStyle, onEachFeature: onEachFeature } as any)} />
        )}
      </MapContainer>

      {/* Bottom Controls */}
      <div className="absolute bottom-6 right-6 z-[400] pointer-events-auto">
        <button 
          className="bg-white dark:bg-navy-900 text-slate-700 dark:text-slate-300 p-3 rounded-full shadow-lg hover:bg-slate-50 transition-colors"
          title="Current Location"
          onClick={() => {
            // Demo location logic
            alert('Geolocation mock: Chennai');
            setSelectedState('Tamil Nadu');
          }}
        >
          <Locate className="w-6 h-6" />
        </button>
      </div>

      {/* Legend */}
      <div className="absolute bottom-6 left-6 z-[400] pointer-events-auto bg-white/90 dark:bg-navy-900/90 backdrop-blur-md rounded-xl shadow-lg p-4">
        <div className="text-xs font-bold uppercase text-slate-500 mb-2">Legend</div>
        <div className="flex flex-col space-y-2 text-sm">
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-red-500 opacity-50 rounded"></div>
            <span>High</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-amber-500 opacity-50 rounded"></div>
            <span>Moderate</span>
          </div>
          <div className="flex items-center space-x-2">
            <div className="w-4 h-4 bg-blue-500 opacity-50 rounded"></div>
            <span>Low</span>
          </div>
        </div>
      </div>
    </div>
  );
}
