from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from datetime import datetime
from app.db.models import DBLocation, HistoricalWeather
from app.schemas.climate import ClimateAnalyzeRequest, ClimateAnalyzeResponse, ClimateTrendResponse

class ClimateAnalyticsService:
    async def analyze(self, req: ClimateAnalyzeRequest, db: AsyncSession):
        # Find Location ID
        result = await db.execute(select(DBLocation.id).filter(
            DBLocation.latitude == req.location.latitude,
            DBLocation.longitude == req.location.longitude
        ))
        loc_id = result.scalars().first()
        
        if not loc_id:
            return None # No data

        start_dt = datetime.strptime(req.time_range.start, "%Y-%m-%d")
        end_dt = datetime.strptime(req.time_range.end, "%Y-%m-%d")

        query = select(HistoricalWeather).filter(
            HistoricalWeather.location_id == loc_id,
            HistoricalWeather.timestamp >= start_dt,
            HistoricalWeather.timestamp <= end_dt
        )
        
        records = (await db.execute(query)).scalars().all()
        if not records:
            return None
            
        # Ensure chronological order for proper charting and time-series analysis
        records = sorted(records, key=lambda r: r.timestamp)
            
        data_points = len(records)
        
        if req.analysis == "trend":
            # Basic linear trend (y = mx + b)
            if req.parameter == "temperature":
                vals = [r.temperature for r in records]
                unit = "°C/year"
            else:
                vals = [r.rainfall for r in records]
                unit = "mm/year"
                
            # Use actual days since the first record as X to be mathematically robust
            min_ts = records[0].timestamp
            x = [(r.timestamp - min_ts).days for r in records]
            n = len(vals)
            
            mean_x = sum(x) / n
            mean_y = sum(vals) / n
            numerator = sum((xi - mean_x) * (yi - mean_y) for xi, yi in zip(x, vals))
            denominator = sum((xi - mean_x)**2 for xi in x)
            slope = (numerator / denominator) * 365.25 if denominator != 0 else 0
            
            direction = "increasing" if slope > 0 else "decreasing"
            if abs(slope) < 0.01:
                direction = "stable"
                
            series = [{"date": r.timestamp.strftime("%Y-%m-%d"), "value": r.temperature if req.parameter=="temperature" else r.rainfall} for r in records]
            
            return ClimateTrendResponse(
                parameter=req.parameter,
                analysis="trend",
                trend={"direction": direction, "slope": round(slope, 3), "unit": unit},
                historical_series=series[::len(series)//20 or 1] # Sample 20 points for chart
            )

        elif req.analysis == "average":
            if req.parameter == "temperature":
                val = sum(r.temperature for r in records) / data_points
                unit = "°C"
            elif req.parameter == "rainfall":
                val = sum(r.rainfall for r in records) / data_points
                unit = "mm"
                
            return ClimateAnalyzeResponse(
                location={"name": req.location.name},
                period={"start": req.time_range.start, "end": req.time_range.end},
                parameter=req.parameter,
                analysis="average",
                result={"value": round(val, 2), "unit": unit},
                data_points=data_points,
                source={"name": "Open-Meteo Archive"}
            )
            
        elif req.analysis == "total" and req.parameter == "rainfall":
            val = sum(r.rainfall for r in records)
            return ClimateAnalyzeResponse(
                location={"name": req.location.name},
                period={"start": req.time_range.start, "end": req.time_range.end},
                parameter="rainfall",
                analysis="total",
                result={"value": round(val, 2), "unit": "mm"},
                data_points=data_points,
                source={"name": "Open-Meteo Archive"}
            )
