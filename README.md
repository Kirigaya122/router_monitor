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

| Router                            | Status     |
| --------------------------------- | ---------- |
| TNM Box R023 (ERGO R023 platform) | ✅ Working |
| Others                            | 🚧 Planned |

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
```

The app parses the XML response into typed Dart models and displays them in the UI.

---

## Requirements

- Flutter SDK (Dart 3.13+)
- A device connected to the router's Wi-Fi network
- Android, Linux, or Windows

---

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/Kirigaya122/router_monitor.git
cd router_monitor
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

```bash
flutter run -d linux    # or -d android, -d windows
```

You'll be prompted for your router's admin username and password on the login screen. These are not stored anywhere.

### 4. Build a release APK (Android)

```bash
flutter build apk --release
```

> **Note:** The release build requires `INTERNET` permission and `android:usesCleartextTraffic="true"` in `AndroidManifest.xml`, since the router uses plain HTTP on the local network.

---

## Project Structure

```
lib/
├── main.dart
├── router/
│   ├── router_client.dart              # HTTP + Digest auth + session
│   ├── router_xml.dart                 # XML request builder
│   ├── router_models.dart              # Data models
│   ├── router_link_context.dart        # Cellular context model
│   ├── parsers/                        # XML → Dart parsers
│   ├── router_utils/                   # Formatters, speed calc, decoders
│   └── tests/                          # Standalone test scripts
├── services/
│   └── router_service.dart             # Coordinates client + parsers
└── screens/
    ├── router_login_screen.dart
    ├── dashboard_screen.dart
    └── connected_devices_screen.dart
```

---

## Security Notes

- Router credentials are entered at runtime and **not persisted to disk**.
- The app only works when connected to the router's local network.
- The router uses **HTTP, not HTTPS**, so traffic between the app and the router is not encrypted. This is fine on a trusted local network, but do not expose the router's admin interface to the internet.
- The CSRF token used by the R023 is hardcoded in the router's firmware and is not a secret in the traditional sense — it is not a substitute for authentication.

---

## Roadmap

- [x] TNM Box R023 support
- [x] Live speed calculation
- [x] Connected devices screen
- [x] Proper login and logout
- [ ] Configurable router IP
- [ ] Support for more routers (Huawei, ZTE, TP-Link, Tenda)
- [ ] Router auto-detection
- [ ] iOS support
- [ ] SMS management (if supported by router)
- [ ] Router operations (reboot, Wi-Fi toggle, network mode)

---

## Disclaimer

This project is not affiliated with TNM, ERGO, or any router manufacturer. It was built by reverse-engineering the router's own web interface for personal use. Use at your own risk, and only on routers you own or have explicit permission to access.

---

## License

```
Copyright (c) 2026 Owen Kirito Swilimba

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---
```
