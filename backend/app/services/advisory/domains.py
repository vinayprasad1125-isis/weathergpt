from typing import Any, Optional
from app.schemas.advisory import AdvisoryResponse, AdvisoryFactor

# ---------------------------------------------------------------------------
# Configurable Advisory Thresholds
# ---------------------------------------------------------------------------

AGRICULTURE_THRESHOLDS = {
    "pesticide_spraying": {
        "wind_speed_max_kmh": 15.0,
        "wind_speed_caution_kmh": 10.0,
        "temp_min_c": 15.0,
        "temp_max_c": 35.0,
        "humidity_min_pct": 40,
        "humidity_max_pct": 90,
        "precip_washoff_mm": 2.0,
        "rain_prob_high_pct": 40,
        "rain_prob_caution_pct": 20,
    },
    "irrigation": {
        "precip_skip_mm": 5.0,
        "rain_prob_skip_pct": 60,
    }
}

AVIATION_THRESHOLDS = {
    "wind_speed_high_kmh": 40.0,
    "visibility_low_km": 3.0,
    "visibility_ifr_km": 1.5,
}

MARINE_THRESHOLDS = {
    "wind_speed_small_craft_kmh": 30.0,
    "wind_speed_gale_kmh": 50.0,
    "wave_height_small_craft_m": 2.0,
    "wave_height_gale_m": 4.0,
}

URBAN_THRESHOLDS = {
    "precip_flood_risk_mm": 10.0,
    "temp_heat_alert_c": 35.0,
}


def _get_field(data: dict, *keys, default=None):
    """Try multiple key names in order, return the first found non-None value."""
    for key in keys:
        v = data.get(key)
        if v is not None:
            return v
    return default


def _factor(parameter: str, value: Any, available: bool = True) -> AdvisoryFactor:
    return AdvisoryFactor(
        parameter=parameter,
        value=value if available else "unavailable"
    )


class BaseAdvisoryService:
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        raise NotImplementedError


class AgricultureAdvisoryService(BaseAdvisoryService):
    """
    Agricultural advisory covering all relevant meteorological fields.
    Reads from both the current weather block AND the forecast block if provided.
    Uses configurable thresholds defined in AGRICULTURE_THRESHOLDS.
    """

    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        current = weather_data.get("current", {})
        forecast = weather_data.get("forecast", {})

        temp = _get_field(current, "temperature", "temperature_2m")
        humidity = _get_field(current, "humidity", "relative_humidity_2m")
        wind_speed = _get_field(current, "wind_speed", "wind_speed_10m")
        wind_direction = _get_field(current, "wind_direction", "wind_direction_10m")
        precipitation = _get_field(current, "precipitation", default=0.0)
        cloud_cover = _get_field(current, "cloud_cover", default=None)
        condition = _get_field(current, "condition", "weather_code")

        hourly_rain_probs = forecast.get("hourly_rain_probs_next_12h", [])
        rain_prob_max = max(hourly_rain_probs) if hourly_rain_probs else \
            _get_field(forecast, "precipitation_probability_max", default=None)

        factors = [
            _factor("temperature_c", temp, temp is not None),
            _factor("humidity_pct", humidity, humidity is not None),
            _factor("wind_speed_kmh", wind_speed, wind_speed is not None),
            _factor("wind_direction", wind_direction, wind_direction is not None),
            _factor("current_precipitation_mm", precipitation, precipitation is not None),
            _factor("rain_probability_next_12h_pct", rain_prob_max, rain_prob_max is not None),
            _factor("cloud_cover_pct", cloud_cover, cloud_cover is not None),
            _factor("condition", condition, condition is not None),
        ]

        if advisory_type and advisory_type in ("pesticide_spraying", "pesticide", "spraying"):
            return self._pesticide_advisory(
                temp, humidity, wind_speed, wind_direction,
                precipitation, rain_prob_max, cloud_cover, condition,
                factors, location
            )
        else:
            return self._general_agriculture_advisory(
                precipitation, rain_prob_max, factors, location
            )

    def _pesticide_advisory(self, temp, humidity, wind_speed, wind_direction,
                             precipitation, rain_prob_max, cloud_cover, condition,
                             factors, location):
        t = AGRICULTURE_THRESHOLDS["pesticide_spraying"]
        issues = []
        cautions = []
        missing = []

        if wind_speed is None:
            missing.append("wind speed")
        elif wind_speed > t["wind_speed_max_kmh"]:
            issues.append(
                f"Wind speed is {wind_speed} km/h (>{t['wind_speed_max_kmh']} km/h threshold). "
                "High spray drift risk — do NOT spray."
            )
        elif wind_speed > t["wind_speed_caution_kmh"]:
            cautions.append(
                f"Wind speed is {wind_speed} km/h. Moderate drift risk — spray only early morning."
            )

        if precipitation is not None and precipitation > t["precip_washoff_mm"]:
            issues.append(
                f"Current precipitation is {precipitation} mm (>{t['precip_washoff_mm']} mm). "
                "Active rainfall will wash off any applied pesticide."
            )

        if rain_prob_max is None:
            missing.append("rain probability forecast")
        elif rain_prob_max >= t["rain_prob_high_pct"]:
            issues.append(
                f"Rain probability in next 12 hours is {rain_prob_max}% "
                f"(>={t['rain_prob_high_pct']}%). High washoff risk — avoid spraying."
            )
        elif rain_prob_max >= t["rain_prob_caution_pct"]:
            cautions.append(
                f"Rain probability in next 12 hours is {rain_prob_max}%. "
                "Moderate chance of rain — confirm forecast before spraying."
            )

        if temp is None:
            missing.append("temperature")
        elif temp > t["temp_max_c"]:
            cautions.append(
                f"Temperature is {temp}°C (>{t['temp_max_c']}°C). "
                "High heat may cause rapid evaporation — spray early morning."
            )
        elif temp < t["temp_min_c"]:
            cautions.append(
                f"Temperature is {temp}°C (<{t['temp_min_c']}°C). "
                "Low temperature may reduce pesticide efficacy."
            )

        if humidity is None:
            missing.append("relative humidity")
        elif humidity > t["humidity_max_pct"]:
            cautions.append(
                f"Humidity is {humidity}% (>{t['humidity_max_pct']}%). "
                "Very high humidity may dilute contact pesticide effectiveness."
            )
        elif humidity < t["humidity_min_pct"]:
            cautions.append(
                f"Humidity is {humidity}% (<{t['humidity_min_pct']}%). "
                "Low humidity increases evaporation losses."
            )

        if issues:
            verdict = "NOT SUITABLE"
            summary = "Conditions are NOT suitable for pesticide spraying right now."
        elif cautions:
            verdict = "USE CAUTION"
            summary = "Conditions are borderline. Proceed with caution or reschedule."
        elif missing:
            verdict = "UNCERTAIN"
            summary = "Some weather data is unavailable. Advisory is uncertain."
        else:
            verdict = "SUITABLE"
            summary = "Current conditions appear suitable for pesticide spraying."

        recommendations = [f"Verdict: {verdict}"] + issues + cautions
        if missing:
            recommendations.append(
                f"Note: The following data could not be retrieved: {', '.join(missing)}. "
                "Recheck the latest forecast before proceeding."
            )
        recommendations.append(
            "Always verify the latest forecast immediately before spraying as conditions change rapidly."
        )

        return AdvisoryResponse(
            domain="agriculture",
            location=location,
            summary=summary,
            factors=factors,
            recommendations=recommendations,
            source="Open-Meteo + WeatherGPT Rule Engine"
        )

    def _general_agriculture_advisory(self, precipitation, rain_prob_max, factors, location):
        t = AGRICULTURE_THRESHOLDS["irrigation"]
        recommendations = []

        if precipitation is not None and precipitation > t["precip_skip_mm"]:
            summary = "Significant rainfall is occurring."
            recommendations.append("Consider postponing irrigation — fields are receiving natural rainfall.")
        elif rain_prob_max is not None and rain_prob_max >= t["rain_prob_skip_pct"]:
            summary = "High probability of rainfall forecast."
            recommendations.append(
                f"Rain probability is {rain_prob_max}%. Consider delaying irrigation."
            )
        else:
            summary = "Dry or low-rain conditions expected."
            recommendations.append("Standard irrigation schedules can be maintained.")

        recommendations.append("Always verify the latest forecast before planning field operations.")

        return AdvisoryResponse(
            domain="agriculture",
            location=location,
            summary=summary,
            factors=factors,
            recommendations=recommendations,
            source="Open-Meteo + WeatherGPT Rule Engine"
        )


class AviationAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        current = weather_data.get("current", {})
        wind = _get_field(current, "wind_speed", "wind_speed_10m", default=0.0)
        vis = _get_field(current, "visibility", default=10.0)
        condition = _get_field(current, "condition", default="Unknown")
        cloud_cover = _get_field(current, "cloud_cover", default=None)

        t = AVIATION_THRESHOLDS
        factors = [
            _factor("Wind speed (km/h)", wind),
            _factor("Visibility (km)", vis),
            _factor("Condition", condition),
            _factor("Cloud cover (%)", cloud_cover, cloud_cover is not None),
        ]

        recommendations = ["Check full NOTAMs and METARs before flying."]
        if wind > t["wind_speed_high_kmh"]:
            recommendations.append(
                f"Wind speed is {wind} km/h. High wind shear potential — exercise caution during approach."
            )
        if vis < t["visibility_ifr_km"]:
            recommendations.append(f"Visibility is {vis} km. IFR conditions — instrument-rated pilots only.")
        elif vis < t["visibility_low_km"]:
            recommendations.append(f"Visibility is {vis} km. Marginal VMC — IFR protocols may be required.")

        return AdvisoryResponse(
            domain="aviation", location=location,
            summary="Aviation Weather Briefing — verify with ATC and official METARs.",
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )


class MarineAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        
        # 1. Fetch relevant time block
        marine_data = weather_data.get("marine", {})
        forecast_time_str = "Current conditions"
        
        current_data = marine_data.get("current", {})
        hourly_data = marine_data.get("hourly", {})
        
        mc = current_data
        
        # Super simple time range parsing for MVP
        if time_range and time_range != "today" and time_range != "now":
            if "tomorrow" in time_range:
                # Naively pick tomorrow morning (e.g. index 30 which is usually tomorrow 06:00 if 0 is today 00:00)
                # But hourly arrays from Open-Meteo start from today 00:00. So tomorrow 06:00 is 24 + 6 = 30.
                idx = 30
                if "hourly" in marine_data and "wave_height" in marine_data["hourly"] and len(marine_data["hourly"]["wave_height"]) > idx:
                    mc = {k: v[idx] for k, v in marine_data["hourly"].items() if isinstance(v, list) and len(v) > idx}
                    forecast_time_str = f"Forecast (index {idx}h)"
                else:
                    forecast_time_str = "Forecast (fallback to current)"
            else:
                forecast_time_str = f"Forecast ({time_range})"
        
        # 2. Extract marine variables
        wave_height = _get_field(mc, "wave_height", default=None)
        wave_direction = _get_field(mc, "wave_direction", default=None)
        wave_period = _get_field(mc, "wave_period", default=None)
        swell_height = _get_field(mc, "swell_wave_height", default=None)
        swell_dir = _get_field(mc, "swell_wave_direction", default=None)
        ocean_vel = _get_field(mc, "ocean_current_velocity", default=None)
        sea_temp = _get_field(mc, "sea_surface_temperature", default=None)
        
        # 3. Extract weather variables (from standard weather response)
        weather_current = weather_data.get("current", {})
        wind = _get_field(weather_current, "wind_speed", "wind_speed_10m", default=0.0)
        wind_dir = _get_field(weather_current, "wind_direction", "wind_direction_10m", default=None)
        condition = _get_field(weather_current, "condition", default="Unknown")
        temp = _get_field(weather_current, "temperature", "temperature_2m", default=None)

        factors = [
            # Marine Factors
            AdvisoryFactor(parameter="Wave height (m)", value=wave_height if wave_height is not None else "unavailable", category="marine"),
            AdvisoryFactor(parameter="Wave direction (°)", value=wave_direction if wave_direction is not None else "unavailable", category="marine"),
            AdvisoryFactor(parameter="Wave period (s)", value=wave_period if wave_period is not None else "unavailable", category="marine"),
            AdvisoryFactor(parameter="Swell height (m)", value=swell_height if swell_height is not None else "unavailable", category="marine"),
            AdvisoryFactor(parameter="Ocean current (km/h)", value=ocean_vel if ocean_vel is not None else "unavailable", category="marine"),
            AdvisoryFactor(parameter="Sea temperature (°C)", value=sea_temp if sea_temp is not None else "unavailable", category="marine"),
            # Weather Factors
            AdvisoryFactor(parameter="Wind speed (km/h)", value=wind, category="weather"),
            AdvisoryFactor(parameter="Wind direction (°)", value=wind_dir if wind_dir is not None else "unavailable", category="weather"),
            AdvisoryFactor(parameter="Condition", value=condition, category="weather"),
            AdvisoryFactor(parameter="Temperature (°C)", value=temp if temp is not None else "unavailable", category="weather")
        ]
        
        # 4. Generate Marine Assessment
        category = "Relatively Calm"
        severity = "low"
        reasons = []
        limitations = [
            "This is a forecast-based assessment, not a navigation or safety clearance.",
            "Local conditions may differ.",
            "Official marine advisories (like INCOIS) should be checked before departure."
        ]
        
        # Check thresholds
        if wave_height is None:
            category = "Unknown"
            severity = "unknown"
            reasons.append("Wave height forecast is unavailable.")
        elif wave_height > 4.0 or wind > 50.0:
            category = "Very Rough"
            severity = "critical"
            reasons.append(f"Wave height is {wave_height}m and/or wind is {wind}km/h, indicating severe conditions.")
        elif wave_height > 2.5 or wind > 40.0:
            category = "Rough"
            severity = "high"
            reasons.append(f"Wave height is {wave_height}m and/or wind is {wind}km/h, indicating rough conditions.")
        elif wave_height > 1.0 or wind > 25.0:
            category = "Moderate"
            severity = "moderate"
            reasons.append(f"Wave height is {wave_height}m and/or wind is {wind}km/h, indicating moderate chop.")
        else:
            reasons.append("Low forecast wave height and relatively low wind/current indicate relatively calm conditions.")

        from app.schemas.advisory import MarineAssessment
        assessment = MarineAssessment(
            category=category,
            severity=severity,
            reasons=reasons,
            limitations=limitations
        )

        return AdvisoryResponse(
            domain="marine", 
            location=location,
            summary="Marine Weather Briefing.",
            factors=factors, 
            recommendations=[],
            assessment=assessment,
            forecast_time=forecast_time_str,
            source="Open-Meteo Marine API"
        )


class UrbanAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        current = weather_data.get("current", {})
        precip = _get_field(current, "precipitation", default=0.0)
        temp = _get_field(current, "temperature", "temperature_2m", default=None)

        t = URBAN_THRESHOLDS
        factors = [
            _factor("current_precipitation_mm", precip),
            _factor("temperature_c", temp, temp is not None),
        ]
        recommendations = []
        if precip > t["precip_flood_risk_mm"]:
            recommendations.append("Heavy rainfall ongoing. Flood-prone area awareness required.")
        if temp is not None and temp > t["temp_heat_alert_c"]:
            recommendations.append(
                f"Temperature is {temp}°C. High heat — outdoor events need hydration stations."
            )
        if not recommendations:
            recommendations.append("Standard urban operations can continue normally.")

        return AdvisoryResponse(
            domain="urban", location=location,
            summary="Urban Planning & Operations Briefing.",
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )


class DisasterAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None, time_range: str = "today") -> AdvisoryResponse:
        factors = [_factor("active_alerts_count", len(alerts))]
        if not alerts:
            summary = "No active official warnings."
            recommendations = ["No immediate disaster risks identified from authoritative sources."]
        else:
            summary = f"{len(alerts)} active official warning(s)."
            recommendations = [f"Official Warning: {a.get('headline', 'See full alert')}" for a in alerts]
        return AdvisoryResponse(
            domain="disaster", location=location, summary=summary,
            factors=factors, recommendations=recommendations, source="WeatherGPT Rule Engine"
        )
