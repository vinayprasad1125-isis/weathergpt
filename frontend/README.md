# WeatherGPT Web (React + Vite + TypeScript)

WeatherGPT frontend migrated from Flutter to a high-performance, accessible React web application.

## Features

- **Dashboard (Home):** Real-time weather cards, 7-day forecast ribbon, quick alert highlights, and quick access floating chat action.
- **Interactive Geospatial Map:** Leaflet map rendered with India states boundaries (`india_states.geojson`) and multi-layer overlays (Temperature, Rainfall, Cyclone tracking, etc.).
- **Forecast & Alerts:** Detailed hourly & daily forecasts with Lucide weather indicators and severity-tiered weather alert cards.
- **Aviation Weather:** METAR and TAF decoding and observation viewer with 4-letter ICAO validation.
- **Climate Trends:** 120-year historical climate analysis powered by Recharts using `india_temperature_1901_2025.json`, including automated linear trend calculation.
- **Advisories:** Sector-specific recommendations (Agriculture, Aviation, Marine, Urban, Disaster) with temperature and precipitation insights.
- **AI Chat & Voice Assistant:** Interactive assistant featuring speech synthesis (TTS), voice input (Speech Recognition), and weather query intent resolution.
- **Personalization:** Persistent light/dark mode and multi-language support (English, Hindi, Tamil) via `localStorage`.

## Environment Variables

Configure via `.env` or pass when launching:

```env
# Operating mode: 'mock' (default, runs self-contained without backend) or 'api'
VITE_DATA_MODE=mock

# Base URL for WeatherGPT FastAPI backend when in 'api' mode
VITE_API_BASE_URL=http://localhost:8000
```

## Getting Started

### Install Dependencies
```bash
npm install
```

### Start Development Server
```bash
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

### Run Automated Tests
```bash
npm test
```

### Run Linter
```bash
npm run lint
```

### Production Build
```bash
npm run build
```
The optimized bundle will be created in `dist/`.
