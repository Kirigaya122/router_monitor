# Router Monitor

A Flutter app for monitoring 4G/LTE routers locally over your Wi-Fi network.

Instead of opening the router's web admin panel in a browser every time, Router Monitor gives you a native dashboard with live battery status, signal strength, data usage, connected devices, and more.

> ⚠️ **Status:** Early development (v1). Currently only supports the **TNM Box R023**. Support for more routers is planned.

---

## Features

- **Live dashboard**
  - Battery percentage and charging status
  - Cellular network mode (2G / 3G / LTE / 4G+)
  - Signal strength (bars and dBm)
  - Network operator
  - Connection status
- **Traffic statistics**
  - Data received/transmitted since power-on
  - Totals since factory reset
  - Live download and upload speed (calculated from successive readings)
- **Connected devices**
  - Device count by connection type (Wi-Fi, LAN, USB)
  - Per-device details: name, IP, MAC, connection duration, DHCP lease time
- **Session management**
  - Runtime login (no hardcoded credentials)
  - Automatic session renewal
  - Proper router logout
- **Auto-refresh** every 5 seconds with silent background polling
- **Cross-platform** — built for Android, Linux, and Windows
- **System theme support** (light/dark)

---

## Supported Routers

| Router | Status |
|---|---|
| TNM Box R023 (ERGO R023 platform) | ✅ Working |
| Others | 🚧 Planned |

The app talks directly to the router's internal XML API over HTTP on your local network. Different router models use different APIs and authentication, so each supported model needs its own adapter.

---

## How It Works

Router Monitor does **not** use the router's public web interface. It communicates with the same internal API the router's own admin panel uses.

For the TNM Box R023, this means:

- **Authentication:** HTTP Digest (realm `Highwmg`), followed by a session cookie
- **API endpoint:** `POST /xml_action.cgi?method=set`
- **Request format:** XML RPC with `obj_path` and `obj_method`
- **CSRF:** a fixed token sent in the `csrftoken` header

Example request:

```xml
<?xml version="1.0" encoding="US-ASCII"?>
<RGW>
  <param>
    <method>call</method>
    <session>000</session>
    <obj_path>statistics</obj_path>
    <obj_method>stat_get_common_data</obj_method>
  </param>
</RGW>
