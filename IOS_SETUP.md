# iOS setup (Network Extension)

VPN connections on iOS run inside a **Packet Tunnel** Network Extension. The
Flutter app cannot create that target by itself, so do these steps once in
Xcode. The extension code is already in `ios/VPNExtension/`.

Identifiers used by the app (`lib/core/app_config.dart`):

| Item | Value |
| --- | --- |
| App Group | `group.com.freevpn.freeVpn` |
| Extension bundle id | `com.freevpn.freeVpn.VPNExtension` |
| System VPN name | `Free VPN` |

If you change any of them, update `AppConfig` to match.

## 1. Open the workspace

```sh
open ios/Runner.xcworkspace
```

Use the `.xcworkspace`, not the `.xcodeproj`. This Flutter project uses Swift
Package Manager (the default since Flutter 3.44), so there is no Podfile to
install.

## 2. Runner capabilities

Select the **Runner** target:

1. **Signing & Capabilities** → choose your Team.
2. **+ Capability** → **App Groups** → add `group.com.freevpn.freeVpn`.
3. **+ Capability** → **Network Extensions** → tick **Packet Tunnel**.

The file `ios/Runner/Runner.entitlements` is provided. If Xcode created a
different entitlements file, set **Build Settings → Code Signing
Entitlements** to `Runner/Runner.entitlements` or copy its keys into yours.

## 3. Add the extension target

1. **File → New → Target… → Network Extension**.
2. Product name: `VPNExtension`.
3. Provider type: **Packet Tunnel**, language: Swift.
4. Minimum deployment: the same iOS version as Runner (12.0 or newer).
5. Finish and activate the scheme.

Then:

1. Set the extension **Signing & Capabilities → Team** to the same team.
2. Set **Build Settings → Product Bundle Identifier** to
   `com.freevpn.freeVpn.VPNExtension`.
3. Replace the generated `VPNExtension/PacketTunnelProvider.swift` with
   `ios/VPNExtension/PacketTunnelProvider.swift`.
4. Replace/merge the generated `VPNExtension/Info.plist` with
   `ios/VPNExtension/Info.plist`.
5. Set **Code Signing Entitlements** to
   `VPNExtension/VPNExtension.entitlements`.
6. Add **App Groups** (`group.com.freevpn.freeVpn`) and **Network
   Extensions → Packet Tunnel** capabilities to the extension as well.

Both targets must use the same development team and the same App Group. The
group must be registered in your Apple Developer account; Xcode does this
automatically when it manages signing.

## 4. Add OpenVPNAdapter to the extension

The extension runs OpenVPN 3 through
[OpenVPNAdapter](https://github.com/ss-abramchuk/OpenVPNAdapter).

Select the **VPNExtension** target in Xcode, then **File → Add Package
Dependencies…**, enter:

```text
https://github.com/ss-abramchuk/OpenVPNAdapter.git
```

Choose **Up to Next Minor** (or exact version) `0.8.0` and add the
**OpenVPNAdapter** product to the **VPNExtension** target only — not to
Runner.

### CocoaPods alternative

If your project uses CocoaPods instead of Swift Package Manager, create a
`Podfile` in `ios/` and add a **top-level** target (not nested inside
`target 'Runner'`, or the extension inherits every Flutter plugin and fails to
link):

```ruby
target 'VPNExtension' do
  use_frameworks!
  pod 'OpenVPNAdapter',
      :git => 'https://github.com/ss-abramchuk/OpenVPNAdapter.git',
      :tag => '0.8.0'
end
```

Then run `pod install` and open the workspace.

## 5. Build phase order

In the **Runner** target → **Build Phases**, drag **Embed Foundation
Extensions** (older Xcode: **Embed App Extensions**) above **Thin Binary** and
**Run Script**. Otherwise Xcode can report *"Cycle inside Runner"*.

## 6. Run on a device

VPN extensions **do not work in the iOS Simulator**. Connect a real device and:

```sh
flutter run
```

The first connection shows the standard iOS "Free VPN would like to add VPN
configurations" prompt. Accept it. If you previously installed a build with
different identifiers, delete the app and the old VPN profile from
**Settings → General → VPN & Device Management** before trying again.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| App builds but connect fails immediately | Extension target missing, wrong bundle id, or `AppConfig.appleProviderBundleIdentifier` does not match. |
| `No VPN configuration` / nothing happens | App Group or Network Extension capability missing on one of the two targets. |
| `Cycle inside Runner` | Fix the build phase order (step 5). |
| Extension crashes on launch | Replace `PacketTunnelProvider.swift` with the provided one and run `pod install` again. |
| Works in debug, not release | Check signing/provisioning for **both** targets and that the App Group is enabled in both profiles. |
| `ProcessException: No such file or directory` during the iOS build | Move the project to a path without spaces or a trailing space (for example `~/AI/free-vpn`). |
| Connection says authentication failed | The volunteer server may be offline or full. Pick another server. |
