/// Application-wide constants.
///
/// The Apple identifiers must match the App Group and the Network Extension
/// bundle identifier configured in Xcode. See `IOS_SETUP.md`.
class AppConfig {
  AppConfig._();

  static const String appName = 'Free VPN';
  static const String vpnGateEndpoint = 'https://www.vpngate.net/api/iphone/';
  static const String vpnGateAttribution = 'Server list provided by VPN Gate';

  /// Shared App Group between Runner and the packet tunnel extension.
  static const String appleGroupIdentifier = 'group.com.freevpn.freeVpn';

  /// Bundle identifier of the Network Extension target.
  static const String appleProviderBundleIdentifier =
      'com.freevpn.freeVpn.VPNExtension';

  /// Name shown in the system VPN settings on iOS.
  static const String appleVpnDescription = 'Free VPN';

  static const Duration requestTimeout = Duration(seconds: 30);

  /// How long a cached server list is considered fresh.
  static const Duration cacheTtl = Duration(minutes: 10);
}
