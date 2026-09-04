import pytest
import urllib.error
import xml.etree.ElementTree as ET
from unittest.mock import patch, MagicMock, AsyncMock
from app.services.sachet_service import SachetService
from app.db.models import Alert
import dateutil.parser
from datetime import datetime, timezone
import asyncio

# Mock XML Data
MOCK_RSS_XML = b"""<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Test Alert</title>
      <guid>123456</guid>
      <link>http://test.cap</link>
    </item>
  </channel>
</rss>
"""

MOCK_CAP_XML = b"""<?xml version="1.0" encoding="UTF-8"?>
<cap:alert xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
  <cap:info>
    <cap:severity>Moderate</cap:severity>
    <cap:event>Test Disaster</cap:event>
    <cap:headline>Test Headline</cap:headline>
  </cap:info>
</cap:alert>
"""

MALFORMED_XML = b"""<?xml version="1.0" encoding="UTF-8"?><rss><unclosed_tag>"""

@pytest.fixture
def mock_session():
    mock_session = AsyncMock()
    
    # Mock the execute().scalar_one_or_none() chain
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute.return_value = mock_result
    
    return mock_session

@pytest.fixture
def mock_notification_service():
    service = AsyncMock()
    service.broadcast_alert.return_value = True
    return service

@pytest.mark.asyncio
async def test_1_first_request():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.AsyncSessionLocal") as mock_db, \
         patch("app.services.sachet_service.NotificationService") as mock_notif_cls:
        
        # Setup mocks
        mock_response_rss = MagicMock()
        mock_response_rss.__enter__.return_value = mock_response_rss
        mock_response_rss.getcode.return_value = 200
        mock_response_rss.getheaders.return_value = [("ETag", "test-etag")]
        mock_response_rss.read.return_value = MOCK_RSS_XML
        
        mock_response_cap = MagicMock()
        mock_response_cap.__enter__.return_value = mock_response_cap
        mock_response_cap.getcode.return_value = 200
        mock_response_cap.read.return_value = MOCK_CAP_XML
        
        mock_urlopen.side_effect = [mock_response_rss, mock_response_cap]
        
        mock_db_instance = mock_db.return_value.__aenter__.return_value
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None  # No existing alert
        mock_db_instance.execute.return_value = mock_result

        service = SachetService()
        await service.poll_sachet_alerts()
        
        # Assertions
        assert service.cached_etag == "test-etag"
        assert mock_db_instance.add.called
        assert mock_db_instance.commit.called
        # Verify Alert fields
        added_alert = mock_db_instance.add.call_args[0][0]
        assert added_alert.external_id == "123456"
        assert added_alert.severity == "MODERATE"

@pytest.mark.asyncio
async def test_2_unchanged_feed():
    with patch("urllib.request.urlopen") as mock_urlopen:
        mock_response_rss = MagicMock()
        mock_response_rss.getcode.return_value = 304
        mock_urlopen.return_value.__enter__.return_value = mock_response_rss
        
        service = SachetService()
        service.cached_etag = "test-etag"
        await service.poll_sachet_alerts()
        
        # Only 1 URL open should happen (RSS), no CAP fetch
        assert mock_urlopen.call_count == 1

@pytest.mark.asyncio
async def test_3_updated_feed():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.AsyncSessionLocal") as mock_db:
         
        mock_response_rss = MagicMock()
        mock_response_rss.__enter__.return_value = mock_response_rss
        mock_response_rss.getcode.return_value = 200
        mock_response_rss.getheaders.return_value = [("ETag", "new-etag")]
        mock_response_rss.read.return_value = MOCK_RSS_XML
        
        mock_response_cap = MagicMock()
        mock_response_cap.__enter__.return_value = mock_response_cap
        mock_response_cap.read.return_value = MOCK_CAP_XML
        
        mock_urlopen.side_effect = [mock_response_rss, mock_response_cap]
        
        mock_db_instance = mock_db.return_value.__aenter__.return_value
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db_instance.execute.return_value = mock_result
        
        service = SachetService()
        service.cached_etag = "old-etag"
        await service.poll_sachet_alerts()
        
        assert service.cached_etag == "new-etag"

@pytest.mark.asyncio
async def test_4_duplicate_alert():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.AsyncSessionLocal") as mock_db:
         
        mock_response_rss = MagicMock()
        mock_response_rss.getcode.return_value = 200
        mock_response_rss.getheaders.return_value = []
        mock_response_rss.read.return_value = MOCK_RSS_XML
        mock_urlopen.return_value.__enter__.return_value = mock_response_rss
        
        mock_db_instance = mock_db.return_value.__aenter__.return_value
        mock_result = MagicMock()
        # SIMULATE EXISTING ALERT
        mock_result.scalar_one_or_none.return_value = Alert(external_id="123456") 
        mock_db_instance.execute.return_value = mock_result
        
        service = SachetService()
        await service.poll_sachet_alerts()
        
        # CAP fetch should NOT be called
        assert mock_urlopen.call_count == 1
        assert not mock_db_instance.add.called

@pytest.mark.asyncio
async def test_7_network_failure():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.logger") as mock_logger:
        
        mock_urlopen.side_effect = urllib.error.URLError("Network unreachable")
        
        service = SachetService()
        await service.poll_sachet_alerts()
        
        # Should catch gracefully and log
        mock_logger.error.assert_called_with("[SACHET] Network/DNS failure polling feed: <urlopen error Network unreachable>")

@pytest.mark.asyncio
async def test_8_malformed_xml():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.logger") as mock_logger:
        
        mock_response_rss = MagicMock()
        mock_response_rss.getcode.return_value = 200
        mock_response_rss.getheaders.return_value = []
        mock_response_rss.read.return_value = MALFORMED_XML
        mock_urlopen.return_value.__enter__.return_value = mock_response_rss
        
        service = SachetService()
        await service.poll_sachet_alerts()
        
        # Verify log output matches malformed XML expectation
        mock_logger.error.assert_called_with("[SACHET] Malformed XML in RSS feed: no element found: line 1, column 57")

@pytest.mark.asyncio
async def test_9_fcm_failure():
    with patch("urllib.request.urlopen") as mock_urlopen, \
         patch("app.services.sachet_service.AsyncSessionLocal") as mock_db, \
         patch("app.services.sachet_service.logger") as mock_logger:
        
        mock_response_rss = MagicMock()
        mock_response_rss.__enter__.return_value = mock_response_rss
        mock_response_rss.getcode.return_value = 200
        mock_response_rss.getheaders.return_value = []
        mock_response_rss.read.return_value = MOCK_RSS_XML
        
        mock_response_cap = MagicMock()
        mock_response_cap.__enter__.return_value = mock_response_cap
        mock_response_cap.read.return_value = MOCK_CAP_XML
        mock_urlopen.side_effect = [mock_response_rss, mock_response_cap]
        
        mock_db_instance = mock_db.return_value.__aenter__.return_value
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db_instance.execute.return_value = mock_result
        
        service = SachetService()
        # Mock NotificationService to fail
        service.notification_service.broadcast_alert = AsyncMock(return_value=False)
        
        await service.poll_sachet_alerts()
        
        # Alert should STILL be stored
        assert mock_db_instance.add.called
        assert mock_db_instance.commit.called
        # Log should indicate failure
        mock_logger.info.assert_any_call("[FCM] Notification failed")
