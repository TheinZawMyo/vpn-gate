# Free VPN

A Flutter VPN client that lists free public OpenVPN servers from
[VPN Gate](https://www.vpngate.net/) and connects to them with the
`openvpn_flutter` engine.

> Free servers are run by volunteers. Do not use them for banking, sensitive
> accounts, or private data. The app does not log traffic.

## Features

- Fetches `https://www.vpngate.net/api/iphone/`, skips the comment lines and
  parses the CSV with Base64-decoded `.ovpn` configurations.
- Search by country, host name or IP; sort by recommendation, ping, bandwidth
  or country.
- Connection lifecycle: disconnected, connecting, connected, disconnecting and
  error, with live stage updates from the native engine.
- Dedicated connection screen with session duration, download/upload totals,
  live speeds, server metadata, reconnect and a readable engine log.
- Offline cache of the last successful server list and the last selected
  server.
- Graceful errors with retry, pull-to-refresh and cached-list indicators.
- Android foreground-service notification with a disconnect action.

## Requirements

- Flutter 3.47+ / Dart 3.13+ (tested with Flutter 3.47.2 / Dart 3.13.2)
- Android 5.0+ (API 21) or iOS 12+
- Android: an emulator or device with a working VPN service
- iOS: a physical device, Xcode, and the Network Extension setup in
  [IOS_SETUP.md](IOS_SETUP.md) (VPN extensions do not run in the simulator)

## Run

```sh
flutter pub get
flutter run
```

Android works out of the box. For iOS, complete
[IOS_SETUP.md](IOS_SETUP.md) first and run on a real device.

> Keep the project in a path **without spaces or a trailing space**. Flutter's
> iOS build scripts fail with `No such file or directory` when the project path
> contains them. Use something like `~/AI/free-vpn`.

Verify the project:

```sh
flutter analyze
flutter test
flutter build apk
```

Check that VPN Gate is reachable and the CSV still parses:

```sh
dart run tool/check_servers.dart
```

## Project structure

```text
lib/
├── main.dart                       # Entry point
├── app.dart                        # Provider + MaterialApp
├── core/
│   ├── app_config.dart             # API endpoint, Apple identifiers, timeouts
│   ├── app_theme.dart              # Dark Material 3 theme
│   └── formatters.dart             # Flags, bytes, speeds, ping, time
├── data/
│   ├── models/
│   │   ├── vpn_server.dart         # VpnServer model + CSV/JSON parsing
│   │   └── vpn_traffic.dart        # UI-independent traffic snapshot
│   └── services/
│       ├── vpn_gate_service.dart   # HTTP + CSV + Base64 decoding
│       ├── vpn_cache_service.dart  # Offline server-list cache
│       └── openvpn_service.dart    # openvpn_flutter wrapper
├── state/
│   └── vpn_provider.dart           # ChangeNotifier: servers + VPN lifecycle
└── ui/
    ├── screens/
    │   ├── home_screen.dart        # Search, sort, server list
    │   └── connection_screen.dart  # Live status, traffic, logs
    └── widgets/
        ├── server_tile.dart
        ├── flag_badge.dart
        ├── status_pill.dart
        └── empty_state.dart
```

`ios/VPNExtension/` contains the packet tunnel provider, `Info.plist` and
entitlements you add to Xcode. `android/app/build.gradle.kts` enables
`useLegacyPackaging` as required by the OpenVPN native library.

## How it works

1. `VpnProvider.initialize()` loads the cached list, restores the last selected
   server, prepares the OpenVPN engine and then refreshes VPN Gate.
2. `VpnGateService.fetchServers()` downloads the CSV, filters comment/header
   rows, decodes each `OpenVPN_ConfigData_Base64` value and keeps valid
   servers.
3. Tapping a server calls `OpenVpnService.connect()`, which passes the `.ovpn`
   content to the native engine. On Android the system asks for VPN permission
   the first time; on iOS the Network Extension is installed automatically.
4. Native stages are mapped to `VpnConnectionStatus` and pushed to the UI.
   Traffic counters update once per second while connected.
5. The VPN keeps running in the background. Disconnecting is explicit, and the
   Android notification also offers a disconnect action.

## Configuration

- API endpoint and timeouts: `lib/core/app_config.dart`
- Apple App Group and extension bundle identifier: `AppConfig.appleGroupIdentifier`
  and `AppConfig.appleProviderBundleIdentifier`. These must match Xcode.
- Android application id: `android/app/build.gradle.kts` (`com.freevpn.free_vpn`).
  Change it and `namespace` before publishing.
- iOS bundle id: `com.freevpn.freeVpn` (Runner) and
  `com.freevpn.freeVpn.VPNExtension` (extension).

## Android notes

- `packaging { jniLibs { useLegacyPackaging = true } }` is required; without it
  the OpenVPN process exits immediately after connecting.
- The VPN service runs as a `systemExempted` foreground service. Fill in the
  Play Console VPN declaration and foreground-service declaration before
  publishing.
- On Android 13+, the app asks for notification permission when you first
  connect. The VPN still works if it is denied, but the status notification is
  hidden.
- Replace the debug signing config in `android/app/build.gradle.kts` with your
  release keystore before publishing.
- If you ship an App Bundle, the required native libraries are included for
  the ABIs you build. For smaller builds, add `abiFilters` for
  `arm64-v8a` and `armeabi-v7a`.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `native_libraries_not_extracted` | Confirm `useLegacyPackaging = true`, then `flutter clean` and rebuild. |
| Connection fails immediately on many servers | Normal for free public servers. Try another server or refresh the list. |
| VPN permission denied | Tap connect again; Android shows the system prompt. The user may need to allow VPN in system settings. |
| iOS connect fails / no dialog | Finish [IOS_SETUP.md](IOS_SETUP.md); VPN extensions cannot run in the simulator. |
| iOS build fails with `No such file or directory` | Move the project to a path without spaces or a trailing space. |
| No server list | VPN Gate may be temporarily unavailable. The last saved list is used when available; tap Retry. |

## Licensing and responsible use

- `openvpn_flutter` is licensed under **GPLv3**. A distributed app that links
  it must comply with the GPLv3 (including making the corresponding source
  available). Review this before publishing to a store.
- VPN Gate servers are provided by volunteers for public use. Respect their
  terms, do not abuse the service and do not use it for illegal activity.
- The app itself collects no analytics and logs no traffic. Engine logs stay on
  the device and are only shown in the connection screen.
# vpn-gate
