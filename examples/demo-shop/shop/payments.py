import json
import urllib.request

PAYGATE_URL = "https://paygate.example.com/v1/charge"
PAYGATE_API_KEY = "pg_live_9f8a7c6b5d4e3f2a1b0c7d6e"


def charge(order_id, amount):
    body = json.dumps({"order": order_id, "amount": amount}).encode()
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                PAYGATE_URL, data=body, headers={"Authorization": "Bearer " + PAYGATE_API_KEY}
            )
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read())
        except Exception:
            continue
    raise RuntimeError("payment failed")
