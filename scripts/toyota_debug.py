#!/usr/bin/env python3
"""
Toyota API debug script — mirrors the exact flow used by the iOS app.
Usage:
    python3 scripts/toyota_debug.py --username EMAIL --password PASS --vin VIN
    python3 scripts/toyota_debug.py --username EMAIL --password PASS --vin VIN --verbose
"""

import argparse
import base64
import json
import os
import sys
import urllib.parse
import urllib.request
import uuid

# ── Load .env from repo root ──────────────────────────────────────────────────
_env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
if os.path.exists(_env_path):
    with open(_env_path) as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith("#") and "=" in _line:
                _k, _, _v = _line.partition("=")
                os.environ.setdefault(_k.strip(), _v.strip())

# ── Constants (mirror ToyotaAPIConstants.swift) ───────────────────────────────
TOKEN_URL    = "https://b2c-login.toyota-europe.com/oauth2/realms/root/realms/tme/access_token"
TELEMETRY_URL  = "https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v3/telemetry"
VEHICLES_URL   = "https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v1/vehicle-association/user"
CLIENT_ID    = "oneapp"
BASIC_AUTH   = "basic b25lYXBwOm9uZWFwcA=="   # base64("oneapp:oneapp")
API_KEY      = os.environ.get("TOYOTA_API_KEY", "")
APP_VERSION  = "4.12.0"
BRAND        = "T"
REDIRECT_URI = "com.toyota.oneapp:/oauth2Callback"

if not API_KEY:
    print("ERROR: TOYOTA_API_KEY must be set in .env or environment.")
    print("Copy .env.example to .env and fill in your credentials.")
    sys.exit(1)

def _print_response(label, status, headers, body_bytes, verbose):
    body_str = body_bytes.decode("utf-8", errors="replace")
    print(f"\n{'─'*60}")
    print(f"  {label}")
    print(f"  Status: {status}")
    if verbose:
        print("  Response headers:")
        for k, v in headers.items():
            print(f"    {k}: {v}")
    print("  Body:")
    try:
        parsed = json.loads(body_str)
        print(json.dumps(parsed, indent=4, ensure_ascii=False))
    except Exception:
        print(body_str)
    print(f"{'─'*60}")

def do_request(label, req, verbose):
    if verbose:
        print(f"\n→ {label}")
        print(f"  {req.method} {req.full_url}")
        print("  Request headers:")
        for k, v in req.headers.items():
            print(f"    {k}: {v}")
        if req.data:
            print(f"  Body: {req.data.decode()}")

    try:
        with urllib.request.urlopen(req) as resp:
            status = resp.status
            body   = resp.read()
            hdrs   = dict(resp.headers)
            _print_response(label, status, hdrs, body, verbose)
            return status, body
    except urllib.error.HTTPError as e:
        status = e.code
        body   = e.read()
        hdrs   = dict(e.headers)
        _print_response(f"{label} [HTTP ERROR]", status, hdrs, body, verbose)
        return status, body
    except Exception as ex:
        print(f"\n✗ Network error on {label}: {ex}")
        sys.exit(1)

# ── Step 1: Login ─────────────────────────────────────────────────────────────
def login(username, password, verbose):
    print("\n[STEP 1] Login with username/password")
    params = {
        "client_id":    CLIENT_ID,
        "grant_type":   "password",
        "username":     username,
        "password":     password,
        "redirect_uri": REDIRECT_URI,
        "code_verifier":"plain",
        "scope":        "openid profile",
    }
    body = urllib.parse.urlencode(params).encode()
    req  = urllib.request.Request(TOKEN_URL, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("authorization", BASIC_AUTH)

    status, data = do_request("Login", req, verbose)
    if not (200 <= status < 300):
        print(f"\n✗ Login failed with status {status}. Check credentials.")
        sys.exit(1)

    j = json.loads(data)
    access  = j.get("access_token")
    refresh = j.get("refresh_token")
    if not access or not refresh:
        print(f"\n✗ Missing tokens in response: {j}")
        sys.exit(1)
    print(f"\n✓ Login OK. access_token starts with: {access[:20]}...")
    return access, refresh

# ── Step 2: Refresh (optional, mirrors app flow) ──────────────────────────────
def refresh_token(refresh, verbose):
    print("\n[STEP 2] Refresh access token (mirrors app flow)")
    params = {
        "client_id":    CLIENT_ID,
        "grant_type":   "refresh_token",
        "refresh_token": refresh,
        "redirect_uri": REDIRECT_URI,
        "code_verifier":"plain",
    }
    body = urllib.parse.urlencode(params).encode()
    req  = urllib.request.Request(TOKEN_URL, data=body, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    req.add_header("authorization", BASIC_AUTH)

    status, data = do_request("Token refresh", req, verbose)
    if not (200 <= status < 300):
        print(f"\n✗ Token refresh failed with status {status}.")
        sys.exit(1)

    j = json.loads(data)
    access  = j.get("access_token")
    refresh = j.get("refresh_token")
    if not access or not refresh:
        print(f"\n✗ Missing tokens in refresh response: {j}")
        sys.exit(1)
    print(f"\n✓ Refresh OK. access_token starts with: {access[:20]}...")
    return access, refresh

# ── Step 3: Fetch odometer ────────────────────────────────────────────────────
def decode_jwt_payload(token):
    """Decode JWT payload (no signature verification)."""
    try:
        payload_b64 = token.split(".")[1]
        # Add padding
        padding = 4 - len(payload_b64) % 4
        if padding != 4:
            payload_b64 += "=" * padding
        return json.loads(base64.urlsafe_b64decode(payload_b64))
    except Exception:
        return {}

def try_odometer(label, vin, access_token, extra_headers, verbose):
    """Single odometer attempt with given headers."""
    req = urllib.request.Request(TELEMETRY_URL, method="GET")
    req.add_header("authorization",  f"Bearer {access_token}")
    req.add_header("x-guid",         str(uuid.uuid4()))
    req.add_header("x-correlationid",str(uuid.uuid4()))
    req.add_header("x-appversion",   APP_VERSION)
    req.add_header("x-brand",        BRAND)
    req.add_header("x-channel",      "ONEAPP")
    req.add_header("vin",            vin)
    req.add_header("Accept",         "application/json")
    for k, v in extra_headers.items():
        req.add_header(k, v)
    status, data = do_request(label, req, verbose)
    return status, data

def fetch_odometer(vin, access_token, verbose):
    print(f"\n[STEP 3] Fetch odometer for VIN: {vin}")

    jwt_claims = decode_jwt_payload(access_token)
    user_uuid  = jwt_claims.get("uuid", "")
    print(f"  JWT uuid: {user_uuid}")

    channels = ["ONEAPP", "TOYOTA", "MOBILE", "HYBRID", "MAAS", "B2C"]
    client_refs = [CLIENT_ID, user_uuid]
    api_keys = [API_KEY, None]
    telemetry_urls = [
        TELEMETRY_URL,
        TELEMETRY_URL.replace("/v3/", "/v2/"),
        TELEMETRY_URL.replace("/v3/", "/v1/"),
    ]

    attempts = []
    for url in telemetry_urls:
        for channel in channels:
            for cref in client_refs[:1]:  # only oneapp for now
                for akey in api_keys[:1]:
                    label = f"url={url.split('/')[-2]}/{url.split('/')[-1]} ch={channel}"
                    attempts.append((label, channel, cref, akey, url))


    for label, channel, cref, akey, url in attempts:
        print(f"\n  ── {label}")
        req = urllib.request.Request(url, method="GET")
        req.add_header("authorization",  f"Bearer {access_token}")
        req.add_header("x-guid",         str(uuid.uuid4()))
        req.add_header("x-correlationid",str(uuid.uuid4()))
        req.add_header("x-appversion",   APP_VERSION)
        req.add_header("x-brand",        BRAND)
        req.add_header("x-channel",      channel)
        req.add_header("x-client-ref",   cref)
        if akey:
            req.add_header("x-api-key",  akey)
        req.add_header("vin",            vin)
        req.add_header("Accept",         "application/json")
        status, data = do_request(label, req, False)  # quiet mode
        if 200 <= status < 300:
            try:
                j        = json.loads(data)
                payload  = j.get("payload", {})
                odometer = payload.get("odometer", {})
                value    = odometer.get("value")
                unit     = odometer.get("unit", "km")
                if value is not None:
                    print(f"\n✓ SUCCESS!")
                    print(f"  Odometer: {value} {unit}")
                    print(f"  channel={channel}, client-ref={cref}, api-key={'yes' if akey else 'no'}")
                    print(f"  URL: {url}")
                    return
                else:
                    print(f"  200 OK but no odometer.value. payload={payload}")
            except Exception as ex:
                print(f"  Parse error: {ex}")
        else:
            try:
                body = json.loads(data)
                msgs = body.get("status", {}).get("messages", [{}])
                desc = msgs[0].get("detailedDescription", msgs[0].get("description", "?"))
                print(f"  {status}: {desc}")
            except Exception:
                print(f"  {status}: (unparseable)")

    print("\n✗ All odometer attempts failed — trying to list linked vehicles...")
    list_vehicles(access_token, verbose)

def list_vehicles(access_token, verbose):
    print(f"\n[BONUS] List vehicles linked to account")
    jwt_claims = decode_jwt_payload(access_token)
    user_uuid  = jwt_claims.get("uuid", "")

    endpoints = [
        f"https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v1/vehicle-association/user",
        f"https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v2/vehicle-association/user",
        f"https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v1/vehicle/guid/{user_uuid}/linkedVehicles",
    ]
    for url in endpoints:
        req = urllib.request.Request(url, method="GET")
        req.add_header("authorization",  f"Bearer {access_token}")
        req.add_header("x-guid",         str(uuid.uuid4()))
        req.add_header("x-correlationid",str(uuid.uuid4()))
        req.add_header("x-appversion",   APP_VERSION)
        req.add_header("x-brand",        BRAND)
        req.add_header("x-channel",      "ONEAPP")
        req.add_header("x-client-ref",   CLIENT_ID)
        req.add_header("x-api-key",      API_KEY)
        req.add_header("Accept",         "application/json")
        status, data = do_request(f"GET {url.split('/')[-1]}", req, verbose)
        if 200 <= status < 300:
            print("  ✓ Got vehicle list!")
            return

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="Toyota API debug tool")
    parser.add_argument("--username", default=os.environ.get("TOYOTA_USERNAME"), help="Toyota account email (or set TOYOTA_USERNAME in .env)")
    parser.add_argument("--password", default=os.environ.get("TOYOTA_PASSWORD"), help="Toyota account password (or set TOYOTA_PASSWORD in .env)")
    parser.add_argument("--vin",      default=os.environ.get("TOYOTA_VIN"),      help="Vehicle VIN (or set TOYOTA_VIN in .env)")
    parser.add_argument("--verbose",  action="store_true", help="Print full headers and request details")
    args = parser.parse_args()

    missing = [n for n, v in [("--username", args.username), ("--password", args.password), ("--vin", args.vin)] if not v]
    if missing:
        parser.error(f"Missing required values (pass as args or set in .env): {', '.join(missing)}")

    access, refresh = login(args.username, args.password, args.verbose)
    access, refresh = refresh_token(refresh, args.verbose)
    fetch_odometer(args.vin, access, args.verbose)

if __name__ == "__main__":
    main()
