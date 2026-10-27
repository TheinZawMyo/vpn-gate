import 'package:openvpn_flutter/openvpn_flutter.dart';

import '../../core/app_config.dart';
import '../models/vpn_server.dart';

/// Thin, disposable wrapper around the `openvpn_flutter` engine.
///
/// The provider owns one instance for the lifetime of the app. All platform
/// specific details (Apple App Group, extension identifier) come from
/// [AppConfig].
class OpenVpnService {
  OpenVpnService({required this.onStageChanged, required this.onStatusChanged});

  final void Function(VPNStage stage, String rawStage) onStageChanged;
  final void Function(VpnStatus? status) onStatusChanged;

  OpenVPN? _engine;
  bool _initialized = false;
  Future<void>? _initializing;

  bool get isInitialized => _initialized;

  /// Prepares the native engine. Safe to call more than once, including while
  /// a previous call is still running.
  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initializeOnce();
  }

  Future<void> _initializeOnce() async {
    try {
      _engine?.dispose();
      _engine = null;
      _initialized = false;

      final engine = OpenVPN(
        onVpnStageChanged: onStageChanged,
        onVpnStatusChanged: onStatusChanged,
      );
      _engine = engine;
      await engine.initialize(
        groupIdentifier: AppConfig.appleGroupIdentifier,
        providerBundleIdentifier: AppConfig.appleProviderBundleIdentifier,
        localizedDescription: AppConfig.appleVpnDescription,
        disconnectOnTaskRemoved: true,
      );
      if (engine == _engine) _initialized = true;
    } finally {
      _initializing = null;
    }
  }

  /// Starts (or switches to) the tunnel described by [server].
  ///
  /// Returns `false` when the user denied the Android VPN permission.
  Future<bool> connect(VpnServer server) async {
    final engine = _engine;
    if (engine == null || !_initialized) {
      throw StateError('The VPN engine has not been initialized.');
    }

    final config =
        await OpenVPN.filteredConfig(server.openVpnConfigData) ??
        server.openVpnConfigData;

    return engine.connect(config, server.displayName);
  }

  Future<void> disconnect() async {
    await _engine?.disconnect();
  }

  Future<String?> lastError() async => _engine?.lastError();

  /// Recent engine log lines, oldest first, formatted for display.
  Future<List<String>> logs() async {
    final engine = _engine;
    if (engine == null) return const [];
    final logs = await engine.getLogs();
    return [
      for (final log in logs)
        '${_clock(log.time)} [${log.level.name.toUpperCase()}] ${log.message}',
    ];
  }

  void dispose() {
    _engine?.dispose();
    _engine = null;
    _initialized = false;
  }

  static String _clock(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
