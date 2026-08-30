from app.services.ingestion.base import Provider
import asyncio
import json
import logging
import paho.mqtt.client as mqtt

logger = logging.getLogger(__name__)

class MQTTProvider(Provider):
    @property
    def name(self) -> str:
        return "MQTT_BROKER_PROVIDER"

    def __init__(self, broker_url: str = "localhost", broker_port: int = 1883):
        self.broker_url = broker_url
        self.broker_port = broker_port
        self.client = None
        self.connected = False
        self._message_queue = asyncio.Queue()
        self._loop = None

    async def connect(self):
        logger.info(f"Connecting to MQTT Broker at {self.broker_url}:{self.broker_port}")
        self._loop = asyncio.get_running_loop()
        self.client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)

        def on_connect(client, userdata, flags, reason_code, properties):
            if reason_code == 0:
                logger.info("Connected to MQTT broker")
                self.connected = True
            else:
                logger.error(f"MQTT connection failed: {reason_code}")

        def on_message(client, userdata, msg):
            try:
                payload = json.loads(msg.payload.decode("utf-8"))
                message = {"topic": msg.topic, "payload": payload}
                logger.info(f"MQTT message received: {msg.topic} -> {payload}")
                asyncio.run_coroutine_threadsafe(self._message_queue.put(message), self._loop)
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON received on {msg.topic}")

        self.client.on_connect = on_connect
        self.client.on_message = on_message
        self.client.connect(self.broker_url, self.broker_port, 60)
        self.client.loop_start()

        for _ in range(20):
            if self.connected:
                return
            await asyncio.sleep(0.1)
        raise ConnectionError("Could not connect to MQTT broker")

    async def disconnect(self):
        logger.info(f"Disconnecting from MQTT Broker at {self.broker_url}:{self.broker_port}")
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
        self.connected = False
        self.client = None

    async def fetch_data(self, topic: str):
        if not self.connected:
            raise ConnectionError("MQTT Broker not connected")
        
        logger.info(f"Subscribing to MQTT topic: {topic}")
        result, _ = self.client.subscribe(topic)
        
        if result != mqtt.MQTT_ERR_SUCCESS:
            raise ConnectionError(f"Failed to subscribe to topic: {topic}")

        try:
            message = await asyncio.wait_for(self._message_queue.get(), timeout=30)
            return message
        except asyncio.TimeoutError:
            raise TimeoutError(f"No MQTT message received on topic '{topic}' within 30 seconds")
