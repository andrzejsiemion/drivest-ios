#!/usr/bin/env python3
"""
Step 1: Opens the Volvo auth URL in the browser (uses Postman callback)
Step 2: You paste the redirect URL after login
Step 3: Exchanges code for tokens and prints the refresh_token

Run:  python3 get_volvo_token.py
"""
import base64, hashlib, os, sys, urllib.parse, urllib.request, json, subprocess

# Load .env from the repo root (two levels up from scripts/)
_env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
if os.path.exists(_env_path):
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _, _v = _line.partition("=")
                os.environ.setdefault(_k.strip(), _v.strip())

CLIENT_ID     = os.environ.get("VOLVO_CLIENT_ID")
CLIENT_SECRET = os.environ.get("VOLVO_CLIENT_SECRET")

if not CLIENT_ID or not CLIENT_SECRET:
    print("ERROR: VOLVO_CLIENT_ID and VOLVO_CLIENT_SECRET must be set in .env or environment.")
    print("Copy .env.example to .env and fill in your credentials.")
    sys.exit(1)

TOKEN_URL     = "https://volvoid.eu.volvocars.com/as/token.oauth2"
AUTH_URL      = "https://volvoid.eu.volvocars.com/as/authorization.oauth2"
REDIRECT_URI  = "https://oauth.pstmn.io/v1/callback"
SCOPES        = "openid conve:odometer_status"

verifier  = base64.urlsafe_b64encode(os.urandom(40)).rstrip(b"=").decode()
challenge = base64.urlsafe_b64encode(
    hashlib.sha256(verifier.encode()).digest()
).rstrip(b"=").decode()

params = urllib.parse.urlencode({
    "response_type": "code", "client_id": CLIENT_ID,
    "redirect_uri": REDIRECT_URI, "scope": SCOPES,
    "code_challenge": challenge, "code_challenge_method": "S256",
})
auth_url = f"{AUTH_URL}?{params}"

print("\n=== Volvo Token Helper ===")
print("Opening browser for Volvo ID login...")
subprocess.Popen(["open", auth_url])
print("\nAfter login Postman will show a page with the token.")
print("Instead, copy the FULL redirect URL from the browser address bar")
print("(starts with https://oauth.pstmn.io/v1/callback?code=...)\n")
redirect = input("Paste redirect URL here: ").strip()

code = urllib.parse.parse_qs(urllib.parse.urlparse(redirect).query).get("code", [None])[0]
if not code:
    print("ERROR: no 'code' in URL"); sys.exit(1)

creds = base64.b64encode(f"{CLIENT_ID}:{CLIENT_SECRET}".encode()).decode()
body  = urllib.parse.urlencode({
    "grant_type": "authorization_code", "code": code,
    "redirect_uri": REDIRECT_URI, "code_verifier": verifier,
}).encode()
req = urllib.request.Request(TOKEN_URL, data=body, method="POST")
req.add_header("Content-Type", "application/x-www-form-urlencoded")
req.add_header("Authorization", f"Basic {creds}")

with urllib.request.urlopen(req) as resp:
    tokens = json.loads(resp.read())

rt = tokens.get("refresh_token", "")
print(f"\n✅ refresh_token:\n{rt}\n")
print("Paste into: Fuel app → Settings → Connected Services → Volvo")

import time
with open(".secrets", "a") as f:
    f.write(f"\n# {time.strftime('%Y-%m-%d %H:%M')}\nrefresh_token {rt}\n")
print("Also saved to .secrets")
