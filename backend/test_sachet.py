import urllib.request
import xml.etree.ElementTree as ET
import json
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://sachet.ndma.gov.in/cap_public_website/rss/rss_india.xml"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, context=ctx) as response:
        headers = dict(response.getheaders())
        status = response.getcode()
        xml_data = response.read()
        
        print("STATUS:", status)
        print("ETag:", headers.get('ETag'))
        print("Last-Modified:", headers.get('Last-Modified'))
        print("Content-Type:", headers.get('Content-Type'))
        
        try:
            root = ET.fromstring(xml_data)
            print("ROOT TAG:", root.tag)
            
            channel = root.find('channel')
            if channel is not None:
                print("CHANNEL FOUND")
                items = channel.findall('item')
                print("NUMBER OF ITEMS:", len(items))
                if items:
                    print("\nFIRST ITEM FIELDS:")
                    for child in items[0]:
                        print(f"  {child.tag}: {child.text[:100] if child.text else 'None'}")
        except Exception as e:
            print("XML Parse Error:", e)
except Exception as e:
    print("Fetch Error:", e)
