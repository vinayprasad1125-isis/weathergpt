import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

# Update config.py
config_path = os.path.join(base_dir, 'app/core/config.py')
with open(config_path, 'r') as f:
    config_content = f.read()
config_content = config_content.replace(
    'GEOCODING_API_BASE_URL: str = "https://geocoding-api.open-meteo.com/v1"',
    'GEOCODING_API_BASE_URL: str = "https://geocoding-api.open-meteo.com/v1"\\n    LLM_API_KEY: str = ""\\n    LLM_MODEL: str = "gemini-2.5-flash"'
)
with open(config_path, 'w') as f:
    f.write(config_content)

# Update main.py
main_path = os.path.join(base_dir, 'app/main.py')
with open(main_path, 'r') as f:
    main_content = f.read()
main_content = main_content.replace(
    'from app.api.routes import health, weather',
    'from app.api.routes import health, weather, chat'
).replace(
    'app.include_router(weather.router, prefix="/api/v1/weather", tags=["Weather"])',
    'app.include_router(weather.router, prefix="/api/v1/weather", tags=["Weather"])\\napp.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])'
)
with open(main_path, 'w') as f:
    f.write(main_content)

# Update requirements.txt
req_path = os.path.join(base_dir, 'requirements.txt')
with open(req_path, 'a') as f:
    f.write('google-genai\\n')

print("Backend updated successfully.")
