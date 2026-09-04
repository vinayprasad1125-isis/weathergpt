import urllib.request
import ssl
import sys

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://sachet.ndma.gov.in/cap_public_website/FetchXMLFile?identifier=1788518967491020"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req, context=ctx) as response:
        print("STATUS:", response.getcode())
        print(response.read().decode('utf-8'))
except Exception as e:
    print("Fetch Error:", e)
