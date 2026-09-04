# WeatherGPT

WeatherGPT is a comprehensive weather application that combines a robust Python backend with a cross-platform Flutter frontend. The application leverages various APIs and databases to provide meteorological data, alongside generative AI capabilities.

## Tech Stack

### Backend
The backend is a RESTful API built with Python, designed for high performance and asynchronous operations.

- **Language:** Python
- **Framework:** FastAPI
- **Server:** Uvicorn
- **Data Validation:** Pydantic & Pydantic-Settings
- **Database & ORM:** 
  - SQLAlchemy
  - SQLite (`aiosqlite`)
  - PostgreSQL (`asyncpg`, `psycopg2-binary`)
- **Caching & Broker:** Redis
- **IoT / Messaging:** MQTT (`aiomqtt`, `paho-mqtt`)
- **AI Integrations:** Google GenAI (Gemini) & OpenAI SDKs
- **Testing:** pytest & pytest-asyncio

### Frontend
The frontend is built using Flutter, providing a unified cross-platform mobile and web experience.

- **Language:** Dart
- **Framework:** Flutter (SDK ^3.10.4)
- **Networking:** `http`
- **Mapping & GIS:** 
  - `flutter_map`
  - `latlong2`
- **Data Visualization:** `fl_chart`
- **Voice Capabilities:** 
  - `speech_to_text`
  - `flutter_tts`
- **Hardware & Permissions:** 
  - `geolocator`
  - `permission_handler`
- **Icons:** `lucide_icons`

## Project Structure
- `/backend`: Contains the FastAPI application, database configurations, and services.
- `/frontend`: Contains the Flutter application codebase.
