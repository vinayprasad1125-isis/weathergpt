import asyncio
from app.services.alert_service import AlertService

async def main():
    service = AlertService()
    alerts = await service.get_active_alerts(13.0, 80.0, active=True)
    print(alerts)

if __name__ == "__main__":
    asyncio.run(main())
