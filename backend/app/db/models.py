from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.db.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    preferred_language = Column(String, default="en")
    fcm_token = Column(String, nullable=True)
    conversations = relationship("Conversation", back_populates="user")

class DBLocation(Base):
    __tablename__ = "locations"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    region = Column(String, nullable=True)
    country = Column(String, nullable=True)
    latitude = Column(Float)
    longitude = Column(Float)
    timezone = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    historical_data = relationship("HistoricalWeather", back_populates="location")
    weather_observations = relationship("WeatherObservation", back_populates="location")
    forecasts = relationship("Forecast", back_populates="location")
    alerts = relationship("Alert", back_populates="location")
    advisories = relationship("Advisory", back_populates="location")

class WeatherObservation(Base):
    __tablename__ = "weather_observations"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    timestamp = Column(DateTime, index=True)
    temperature = Column(Float)
    humidity = Column(Float, nullable=True)
    rainfall = Column(Float, nullable=True)
    wind_speed = Column(Float, nullable=True)
    wind_direction = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    visibility = Column(Float, nullable=True)
    cloud_cover = Column(Float, nullable=True)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)

    location = relationship("DBLocation", back_populates="weather_observations")

class Forecast(Base):
    __tablename__ = "forecasts"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    forecast_time = Column(DateTime, index=True)
    generated_at = Column(DateTime, index=True)
    temperature = Column(Float)
    precipitation = Column(Float, nullable=True)
    precipitation_probability = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    wind_speed = Column(Float, nullable=True)
    wind_direction = Column(Float, nullable=True)
    pressure = Column(Float, nullable=True)
    source = Column(String)
    model = Column(String, nullable=True) # GFS, WRF, etc.
    
    location = relationship("DBLocation", back_populates="forecasts")

class HistoricalWeather(Base):
    __tablename__ = "historical_weather"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    timestamp = Column(DateTime, index=True)
    temperature = Column(Float)
    rainfall = Column(Float)
    wind_speed = Column(Float)
    source = Column(String)
    
    location = relationship("DBLocation", back_populates="historical_data")

class Alert(Base):
    __tablename__ = "alerts"
    id = Column(Integer, primary_key=True, index=True)
    external_id = Column(String, index=True, nullable=True)
    event_type = Column(String, index=True)
    severity = Column(String, index=True)
    status = Column(String, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    headline = Column(String)
    description = Column(String)
    issued_at = Column(DateTime)
    effective_from = Column(DateTime)
    expires_at = Column(DateTime)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    location = relationship("DBLocation", back_populates="alerts")

class Advisory(Base):
    __tablename__ = "advisories"
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey("locations.id"))
    domain = Column(String, index=True)
    valid_from = Column(DateTime, nullable=True)
    valid_until = Column(DateTime, nullable=True)
    summary = Column(String)
    source = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    location = relationship("DBLocation", back_populates="advisories")

class Conversation(Base):
    __tablename__ = "conversations"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    language = Column(String, default="en")
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation")

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id"))
    role = Column(String) # user, assistant, system
    content = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    conversation = relationship("Conversation", back_populates="messages")
