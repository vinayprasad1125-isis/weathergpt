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
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
        raise NotImplementedError


class AgricultureAdvisoryService(BaseAdvisoryService):
    """
    Agricultural advisory covering all relevant meteorological fields.
    Reads from both the current weather block AND the forecast block if provided.
    Uses configurable thresholds defined in AGRICULTURE_THRESHOLDS.
    """

    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
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
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        wind = _get_field(current, "wind_speed", "wind_speed_10m", default=0.0)
        vis = _get_field(current, "visibility", default=10.0)
        condition = _get_field(current, "condition", default="Unknown")
        cloud_cover = _get_field(current, "cloud_cover", default=None)

        t = AVIATION_THRESHOLDS
        factors = [
            _factor("wind_speed_kmh", wind),
            _factor("visibility_km", vis),
            _factor("condition", condition),
            _factor("cloud_cover_pct", cloud_cover, cloud_cover is not None),
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
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
        current = weather_data.get("current", {})
        wind = _get_field(current, "wind_speed", "wind_speed_10m", default=0.0)
        condition = _get_field(current, "condition", default="Unknown")

        t = MARINE_THRESHOLDS
        factors = [_factor("wind_speed_kmh", wind), _factor("condition", condition)]
        recommendations = ["Wave height data is not available from the current source. Check IMD Marine Bulletin."]

        if wind > t["wind_speed_gale_kmh"]:
            recommendations.append(f"Wind speed is {wind} km/h. Gale conditions — avoid sea operations.")
        elif wind > t["wind_speed_small_craft_kmh"]:
            recommendations.append(f"Wind speed is {wind} km/h. Small craft advisory conditions.")

        return AdvisoryResponse(
            domain="marine", location=location,
            summary="Marine Weather Briefing — verify with IMD Marine Division.",
            factors=factors, recommendations=recommendations, source="Open-Meteo"
        )


class UrbanAdvisoryService(BaseAdvisoryService):
    def process(self, weather_data: dict, alerts: list, location: dict,
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
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
                advisory_type: Optional[str] = None) -> AdvisoryResponse:
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
