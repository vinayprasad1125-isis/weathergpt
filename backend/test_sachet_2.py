import urllib.request
import xml.etree.ElementTree as ET
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req, context=ctx) as response:
    xml_data = response.read()
    root = ET.fromstring(xml_data)
    channel = root.find('channel')
    for item in channel.findall('item')[:3]:
        print("ITEM:")
        for child in item:
            print(f"  {child.tag}: {child.text}")
        print("-" * 20)
