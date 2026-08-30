import json
import logging
from typing import Optional
from app.core.config import settings
from app.schemas.chat import StructuredWeatherQuery

logger = logging.getLogger(__name__)

if settings.LLM_PROVIDER in ["openai", "groq"]:
    from openai import OpenAI

class OpenAILLMService:
    def __init__(self):
        self.api_key = settings.OPENAI_API_KEY
        self.client = None
        if self.api_key:
            if settings.LLM_PROVIDER == "groq":
                self.client = OpenAI(api_key=self.api_key, base_url="https://api.groq.com/openai/v1")
            else:
                self.client = OpenAI(api_key=self.api_key)

    async def extract_query(self, message: str, context_location: Optional[str]) -> StructuredWeatherQuery:
        if not self.client:
            logger.warning("No OPENAI_API_KEY provided. Using mocked structured query.")
            return self._keyword_extract(message, context_location)

        prompt = f"""
You are an expert intent extraction engine for a weather AI called WeatherGPT.
Extract structured information from the user's message.

Rules:
- If the user says 'here' or 'my location', use the context location.
- If the user asks about pesticide spraying, crop spraying, farm spraying → set intent="advisory", user_type="farmer", advisory_type="pesticide_spraying"
- If the user asks about irrigation, watering crops → set intent="advisory", user_type="farmer", advisory_type="irrigation"
- If the user asks about flying, aviation, flight conditions → set intent="advisory", user_type="pilot", advisory_type="flight_briefing"
- For any advisory intent, set data_source="weather_forecast"
- For current weather questions → set data_source="current_weather"
- For forecast questions → set data_source="weather_forecast"

Context Location: {context_location or "None"}
User Message: {message}
"""
        try:
            # Using OpenAI Structured Outputs (beta) with Pydantic
            response = self.client.beta.chat.completions.parse(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": message}
                ],
                response_format=StructuredWeatherQuery
            )
            return response.choices[0].message.parsed
        except Exception as e:
            logger.warning(f"OpenAI unavailable ({str(e)[:80]}). Using keyword fallback for intent extraction.")
            return self._keyword_extract(message, context_location)

    def _keyword_extract(self, message: str, context_location: Optional[str]) -> StructuredWeatherQuery:
        """Rule-based intent extractor — used when LLM is rate-limited or unavailable."""
        msg = message.lower()
        intent = "current_weather"
        user_type = None
        advisory_type = None
        data_source = "current_weather"

        if any(w in msg for w in ["pesticide", "spray", "spraying", "fungicide", "herbicide"]):
            intent, user_type, advisory_type, data_source = "advisory", "farmer", "pesticide_spraying", "weather_forecast"
        elif any(w in msg for w in ["irrigat", "water my crop", "water crops"]):
            intent, user_type, advisory_type, data_source = "advisory", "farmer", "irrigation", "weather_forecast"
        elif any(w in msg for w in ["harvest", "crop", "farm", "agriculture", "fertilizer"]):
            intent, user_type, advisory_type, data_source = "advisory", "farmer", "general", "weather_forecast"
        elif any(w in msg for w in ["fly", "flight", "aviation", "pilot", "landing", "takeoff"]):
            intent, user_type, advisory_type, data_source = "advisory", "pilot", "flight_briefing", "weather_forecast"
        elif any(w in msg for w in ["fish", "marine", "sea", "boat", "sail"]):
            intent, user_type, advisory_type, data_source = "advisory", "fisherman", "marine", "weather_forecast"
        elif any(w in msg for w in ["forecast", "tomorrow", "week", "7 day", "next"]):
            intent, data_source = "forecast", "weather_forecast"
        elif any(w in msg for w in ["alert", "warning", "cyclone", "flood", "storm"]):
            intent, data_source = "alerts", "weather_forecast"

        INDIA_LOCATIONS = [
            "andhra pradesh", "arunachal pradesh", "himachal pradesh", "madhya pradesh",
            "tamil nadu", "tamilnadu", "uttar pradesh", "uttarakhand", "west bengal",
            "andhra", "assam", "bihar", "chhattisgarh", "goa", "gujarat", "haryana",
            "jharkhand", "karnataka", "kerala", "maharashtra", "manipur", "meghalaya",
            "mizoram", "nagaland", "odisha", "orissa", "punjab", "rajasthan", "sikkim",
            "telangana", "tripura", "jammu", "kashmir", "ladakh",
            "mumbai", "bangalore", "bengaluru", "chennai", "kolkata", "hyderabad",
            "delhi", "pune", "ahmedabad", "jaipur", "surat", "lucknow", "kanpur",
            "nagpur", "indore", "thane", "bhopal", "visakhapatnam", "vizag",
            "patna", "vadodara", "ghaziabad", "ludhiana", "agra", "nashik",
            "faridabad", "meerut", "rajkot", "varanasi", "srinagar", "aurangabad",
            "amritsar", "allahabad", "howrah", "coimbatore", "jabalpur", "gwalior",
            "vijayawada", "jodhpur", "madurai", "raipur", "kota", "chandigarh",
            "guwahati", "thiruvananthapuram", "trivandrum", "kochi", "cochin",
            "mysuru", "mysore", "bhubaneswar", "dehradun", "shimla", "pondicherry",
            "puducherry",
        ]
        location = context_location or "Chennai"
        for place in INDIA_LOCATIONS:
            if place in msg:
                location = place.title()
                break

        return StructuredWeatherQuery(
            intent=intent,
            location=location,
            time_range="today",
            parameter="general",
            user_type=user_type,
            advisory_type=advisory_type,
            data_source=data_source
        )

    async def generate_response(self, message: str, weather_data: dict, language: str = "en") -> str:
        """Generic weather response — used for non-advisory queries."""
        if not self.client:
            logger.warning("No LLM_API_KEY provided. Using mocked response.")
            return self._format_weather_direct(weather_data)

        prompt = f"""
You are WeatherGPT, a friendly, highly intelligent weather assistant.
CRITICAL INSTRUCTION: Respond in the language indicated by this code: {language}.
(e.g., 'ta' → Tamil, 'hi' → Hindi, 'en' → English)

STRICT DATA RULES:
- Use ONLY the supplied weather data to make factual claims.
- Do NOT invent temperatures, rainfall, wind speed, humidity, or any weather values.
- If the data does not contain a requested field, explicitly say it is unavailable.

TONE & STYLE RULES:
1. First, always provide the raw data in a clean, list-like structure (e.g., Temp: X°C, Condition: Y). Use emojis if appropriate.
2. Second, provide a detailed but concise explanation of what that means for the user (2-3 sentences).
3. Be conversational, engaging, and helpful in your explanation (e.g., "Yes, you should expect some rain tomorrow!").
4. Do not just output a single robotic sentence. Give a rich, human-like summary.

Weather Data:
{json.dumps(weather_data, indent=2)}
"""
        try:
            response = self.client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": message}
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.warning(f"OpenAI unavailable for generate_response. Formatting data directly.")
            return self._format_weather_direct(weather_data)

    def _format_weather_direct(self, weather_data: dict) -> str:
        """Formats raw weather data into a readable response without LLM."""
        lines = []
        
        # Handle Alerts
        if "alerts" in weather_data:
            alerts = weather_data["alerts"]
            if not alerts:
                lines.append("✅ No active weather alerts for your location.")
            else:
                lines.append(f"🚨 Active Weather Alerts ({len(alerts)}):")
                for a in alerts:
                    lines.append(f"• {a.get('severity', 'Unknown')} Severity: {a.get('event', 'Alert')}")
                    if a.get('description'):
                        lines.append(f"  Description: {a.get('description')}")
        
        # Handle Forecast
        elif "daily" in weather_data:
            lines.append("📅 Weather Forecast:")
            daily = weather_data["daily"]
            for day in daily[:3]: # show up to 3 days
                lines.append(f"• {day.get('date', 'Unknown')}: {day.get('minTemp', '')}°C - {day.get('maxTemp', '')}°C, {day.get('condition', 'Unknown')}")
                
        # Handle Current Weather
        elif "current" in weather_data:
            current = weather_data["current"]
            loc = weather_data.get("location", {})
            loc_name = loc.get("name", "your location") if isinstance(loc, dict) else "your location"
            lines.append(f"🌤️ Current Weather — {loc_name}")
            if current.get("temperature") is not None:
                lines.append(f"🌡️ Temperature: {current['temperature']}°C (feels like {current.get('feels_like', 'N/A')}°C)")
            if current.get("humidity") is not None:
                lines.append(f"💧 Humidity: {current['humidity']}%")
            if current.get("wind_speed") is not None:
                lines.append(f"💨 Wind: {current['wind_speed']} km/h {current.get('wind_direction', '')}")
            if current.get("precipitation") is not None:
                lines.append(f"🌧️ Precipitation: {current['precipitation']} mm")
            if current.get("condition"):
                lines.append(f"🌈 Condition: {current['condition']}")
        else:
            lines.append("No formatted weather data available.")
            
        lines.append("")
        lines.append("_(AI summary unavailable — LLM API quota reached. Raw data shown above.)_")
        return "\n".join(lines)

    async def generate_advisory_response(
        self,
        message: str,
        advisory_data: dict,
        language: str = "en",
        advisory_type: Optional[str] = None
    ) -> str:
        """Domain-specific advisory response."""
        if not self.client:
            logger.warning("No LLM_API_KEY provided. Using mocked advisory response.")
            return self._mock_advisory_text(advisory_data)

        domain = advisory_data.get("domain", "general")
        summary = advisory_data.get("summary", "")
        factors = advisory_data.get("factors", [])
        recommendations = advisory_data.get("recommendations", [])

        factors_text = "\n".join(f"  - {f['parameter']}: {f['value']}" for f in factors)
        recommendations_text = "\n".join(f"  {i+1}. {r}" for i, r in enumerate(recommendations))

        prompt = f"""
You are WeatherGPT, a professional weather advisory system for India.
CRITICAL INSTRUCTION: Respond in the language indicated by this code: {language}.

STRICT RULES:
- You are given PRE-EVALUATED advisory data. Do NOT change, invent, or contradict any values.
- Do NOT fabricate any weather readings. Use ONLY the values provided in "Retrieved Weather Factors".
- If a factor is listed as "unavailable", acknowledge it honestly — do NOT substitute a guess.
- Format your response clearly with emoji headers as shown below.
- Conclude with the exact verdict from the recommendations.

ADVISORY DOMAIN: {domain}
RULE ENGINE SUMMARY: {summary}

RETRIEVED WEATHER FACTORS (REAL DATA — DO NOT MODIFY):
{factors_text}

RULE ENGINE RECOMMENDATIONS:
{recommendations_text}

FORMAT YOUR RESPONSE EXACTLY AS:
🌾 [Domain] Advisory

📍 Location: [from factors if available]
🕐 Time: Current conditions

Then list each retrieved weather factor with its value, one per line.
Then state the recommendation verdict clearly.
Then explain in 2-3 sentences why the conditions are or are not suitable, using the actual values above.
End with: "⚠️ Always recheck the latest forecast before taking action."
"""
        try:
            response = self.client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": prompt},
                    {"role": "user", "content": message}
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            logger.warning("OpenAI unavailable for advisory. Using rule-engine text directly.")
            return self._mock_advisory_text(advisory_data)

    def _mock_advisory_text(self, advisory_data: dict) -> str:
        summary = advisory_data.get("summary", "")
        factors = advisory_data.get("factors", [])
        recommendations = advisory_data.get("recommendations", [])

        lines = [f"Advisory: {summary}", ""]
        lines.append("Weather conditions:")
        for f in factors:
            lines.append(f"  {f['parameter']}: {f['value']}")
        lines.append("")
        lines.append("Recommendations:")
        for r in recommendations:
            lines.append(f"  • {r}")
        lines.append("")
        lines.append("Always recheck the latest forecast before taking action.")
        return "\n".join(lines)
