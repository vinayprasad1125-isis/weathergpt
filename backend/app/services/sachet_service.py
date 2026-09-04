import logging
import urllib.request
import ssl
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
import dateutil.parser
from sqlalchemy.orm import Session
from sqlalchemy.future import select

from app.db.database import AsyncSessionLocal
from app.db.models import Alert
from app.services.notification_service import NotificationService
import uuid

import os

logger = logging.getLogger(__name__)

class SachetService:
    def __init__(self):
        self.rss_url = os.getenv("SACHET_RSS_URL", "https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml")
        self.cached_etag = None
        self.notification_service = NotificationService()
        
        # SSL context to ignore verification if NDMA cert is self-signed/expired
        self.ctx = ssl.create_default_context()
        self.ctx.check_hostname = False
        self.ctx.verify_mode = ssl.CERT_NONE

    async def poll_sachet_alerts(self):
        """Polls the SACHET RSS feed, parses new alerts, and sends notifications."""
        logger.info("[SACHET] Fetching feed")
        
        try:
            req = urllib.request.Request(self.rss_url, headers={'User-Agent': 'WeatherGPT-Worker'})
            if self.cached_etag:
                req.add_header('If-None-Match', self.cached_etag)
                
            with urllib.request.urlopen(req, context=self.ctx, timeout=30) as response:
                status = response.getcode()
                headers = dict(response.getheaders())
                
                if status == 304:
                    logger.info("[SACHET] HTTP 304 - no changes")
                    return
                
                if status == 200:
                    logger.info("[SACHET] HTTP 200")
                    new_etag = headers.get('ETag')
                    if new_etag:
                        self.cached_etag = new_etag
                        
                    xml_data = response.read()
                    await self._process_rss_feed(xml_data)
                    
        except urllib.error.HTTPError as e:
            if e.code == 304:
                logger.info("[SACHET] HTTP 304 - no changes")
            else:
                logger.error(f"[SACHET] HTTP Error polling feed: {e}")
        except urllib.error.URLError as e:
            logger.error(f"[SACHET] Network/DNS failure polling feed: {e}")
        except Exception as e:
            logger.error(f"[SACHET] Unexpected Error polling feed: {e}")

    async def _process_rss_feed(self, xml_data: bytes):
        try:
            root = ET.fromstring(xml_data)
            channel = root.find('channel')
            if channel is None:
                return
                
            items = channel.findall('item')
            logger.info(f"[SACHET] Found {len(items)} alerts in feed.")
            
            async with AsyncSessionLocal() as session:
                for item in items:
                    guid = item.findtext('guid')
                    title = item.findtext('title')
                    link = item.findtext('link')  # CAP URL
                    
                    if not guid or not link:
                        continue
                        
                    # Check for duplicate
                    stmt = select(Alert).where(Alert.external_id == guid)
                    result = await session.execute(stmt)
                    existing_alert = result.scalar_one_or_none()
                    
                    if existing_alert:
                        # Existing alert unchanged
                        logger.info(f"[SACHET] Existing alert unchanged: {guid}")
                        continue
                        
                    logger.info(f"[SACHET] New alert detected: {guid}")
                    await self._fetch_and_store_cap(session, guid, link)
                    
        except ET.ParseError as e:
            logger.error(f"[SACHET] Malformed XML in RSS feed: {e}")
        except Exception as e:
            logger.error(f"[SACHET] Error parsing RSS: {e}")

    async def _fetch_and_store_cap(self, session: Session, guid: str, cap_url: str):
        try:
            req = urllib.request.Request(cap_url, headers={'User-Agent': 'WeatherGPT-Worker'})
            with urllib.request.urlopen(req, context=self.ctx, timeout=30) as response:
                cap_xml = response.read()
                
            root = ET.fromstring(cap_xml)
            # Namespace for CAP 1.2
            ns = {'cap': 'urn:oasis:names:tc:emergency:cap:1.2'}
            
            info = root.find('cap:info', ns)
            if info is None:
                return
                
            severity = info.findtext('cap:severity', default='Unknown', namespaces=ns)
            event_type = info.findtext('cap:event', default='Disaster Alert', namespaces=ns)
            headline = info.findtext('cap:headline', default='Alert', namespaces=ns)
            description = info.findtext('cap:description', default='', namespaces=ns)
            instruction = info.findtext('cap:instruction', default='', namespaces=ns)
            
            # Parse areaDesc — the human-readable affected area
            area = info.find('cap:area', ns)
            area_desc = area.findtext('cap:areaDesc', namespaces=ns) if area is not None else None
            
            # Times
            issued_str = root.findtext('cap:sent', namespaces=ns)
            effective_str = info.findtext('cap:effective', namespaces=ns)
            expires_str = info.findtext('cap:expires', namespaces=ns)
            
            issued_at = dateutil.parser.isoparse(issued_str) if issued_str else datetime.now(timezone.utc)
            effective_from = dateutil.parser.isoparse(effective_str) if effective_str else issued_at
            expires_at = dateutil.parser.isoparse(expires_str) if expires_str else (issued_at)
            
            new_alert = Alert(
                external_id=guid,
                event_type=event_type,
                severity=severity.upper(),
                status="Actual",
                headline=headline,
                area_desc=area_desc,
                description=description + ("\n\nInstruction: " + instruction if instruction else ""),
                issued_at=issued_at.replace(tzinfo=None), # Storing naive in DB
                effective_from=effective_from.replace(tzinfo=None),
                expires_at=expires_at.replace(tzinfo=None),
                source="NDMA SACHET"
            )
            
            session.add(new_alert)
            await session.commit()
            
            logger.info(f"[SACHET] Successfully stored alert {guid}")
            
            # Send Notification if severity is high enough
            if severity.upper() in ["SEVERE", "EXTREME", "MODERATE"]:
                logger.info(f"[FCM] Triggering broadcast for new SACHET alert {guid}")
                success = await self.notification_service.broadcast_alert(
                    alert_id=guid,
                    title=f"NDMA Alert: {event_type}",
                    body=headline
                )
                if success:
                    logger.info(f"[FCM] Notification sent")
                else:
                    logger.info(f"[FCM] Notification failed")
                
        except urllib.error.URLError as e:
            logger.error(f"[SACHET] Network failure fetching CAP for {guid}: {e}")
            await session.rollback()
        except ET.ParseError as e:
            logger.error(f"[SACHET] Malformed XML in CAP for {guid}: {e}")
            await session.rollback()
        except Exception as e:
            logger.error(f"[SACHET] Error parsing CAP for {guid}: {e}")
            await session.rollback()
