from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    WEATHER_API_BASE_URL: str = "https://api.open-meteo.com/v1"
    GEOCODING_API_BASE_URL: str = "https://geocoding-api.open-meteo.com/v1"
    LLM_API_KEY: str = ""
    LLM_MODEL: str = "gemini-1.5-flash"
    OPENAI_API_KEY: str = ""
    OPENAI_MODEL: str = "openai/gpt-oss-20b"
    LLM_PROVIDER: str = "groq"
    
    # MQTT Config
    MQTT_BROKER_URL: str = "localhost"
    MQTT_BROKER_PORT: int = 1883
    MQTT_TOPIC: str = "weather/chennai"
    
    class Config:
        env_file = ".env"

settings = Settings()
