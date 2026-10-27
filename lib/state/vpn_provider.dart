import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/vpn_server.dart';
import '../data/models/vpn_traffic.dart';
import '../data/services/openvpn_service.dart';
import '../data/services/vpn_cache_service.dart';
import '../data/services/vpn_gate_service.dart';

enum VpnConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

enum ServerSort { recommended, fastest, fastestSpeed, country }

extension ServerSortLabel on ServerSort {
  String get label => switch (this) {
    ServerSort.recommended => 'Recommended',
    ServerSort.fastest => 'Lowest ping',
    ServerSort.fastestSpeed => 'Fastest',
    ServerSort.country => 'Country',
  };
}

/// Owns the server list, search/sort state and the VPN lifecycle.
class VpnProvider extends ChangeNotifier {
  VpnProvider({VpnGateService? gateService, VpnCacheService? cacheService})
    : _gateService = gateService ?? VpnGateService(),
      _cacheService = cacheService ?? VpnCacheService() {
    _openVpnService = OpenVpnService(
      onStageChanged: _handleStage,
      onStatusChanged: _handleStatus,
    );
  }

  static const String _selectedServerKey = 'selected_server_json';

  final VpnGateService _gateService;
  final VpnCacheService _cacheService;
  late final OpenVpnService _openVpnService;

  List<VpnServer> _servers = const [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _query = '';
  ServerSort _sort = ServerSort.recommended;
  DateTime? _lastUpdated;
  bool _showingCached = false;

  bool _engineReady = false;
  String? _engineError;

  VpnConnectionStatus _connectionStatus = VpnConnectionStatus.disconnected;
  String _stageLabel = 'Disconnected';
  VpnServer? _selectedServer;
  VpnTraffic _traffic = VpnTraffic.empty;
  String? _connectionError;

  bool _initialized = false;
  bool _disposed = false;
  int _attempt = 0;

  List<VpnServer> get servers => _servers;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String get query => _query;
  ServerSort get sort => _sort;
  DateTime? get lastUpdated => _lastUpdated;
  bool get showingCached => _showingCached;

  bool get engineReady => _engineReady;
  String? get engineError => _engineError;

  VpnConnectionStatus get connectionStatus => _connectionStatus;
  String get stageLabel => _stageLabel;
  VpnServer? get selectedServer => _selectedServer;
  VpnTraffic get traffic => _traffic;
  String? get connectionError => _connectionError;

  bool get isConnected => _connectionStatus == VpnConnectionStatus.connected;
  bool get isBusy =>
      _connectionStatus == VpnConnectionStatus.connecting ||
      _connectionStatus == VpnConnectionStatus.disconnecting;

  String get connectionLabel => switch (_connectionStatus) {
    VpnConnectionStatus.disconnected => 'Not connected',
    VpnConnectionStatus.connecting => 'Connecting',
    VpnConnectionStatus.connected => 'Connected',
    VpnConnectionStatus.disconnecting => 'Disconnecting',
    VpnConnectionStatus.error => 'Connection failed',
  };

  List<VpnServer> get visibleServers {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<VpnServer>.of(_servers)
        : _servers.where((server) {
            return server.countryLong.toLowerCase().contains(query) ||
                server.countryShort.toLowerCase().contains(query) ||
                server.hostName.toLowerCase().contains(query) ||
                server.ip.contains(query);
          }).toList();

    switch (_sort) {
      case ServerSort.recommended:
        filtered.sort((a, b) => b.score.compareTo(a.score));
      case ServerSort.fastest:
        filtered.sort((a, b) {
          if (a.isUnknownPing && b.isUnknownPing) {
            return b.score.compareTo(a.score);
          }
          if (a.isUnknownPing) return 1;
          if (b.isUnknownPing) return -1;
          return a.ping.compareTo(b.ping);
        });
      case ServerSort.fastestSpeed:
        filtered.sort((a, b) => b.speed.compareTo(a.speed));
      case ServerSort.country:
        filtered.sort((a, b) {
          final byCountry = a.countryLong.compareTo(b.countryLong);
          return byCountry != 0 ? byCountry : a.ping.compareTo(b.ping);
        });
    }
    return filtered;
  }

  /// Loads the cache, prepares the engine and refreshes the server list.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadCache();
    await _restoreSelectedServer();

    // The engine can take a while to prepare (especially on iOS); load the
    // server list at the same time instead of waiting for it.
    await Future.wait([_initializeEngine(), refreshServers()]);
  }

  Future<void> refreshServers() async {
    if (_disposed || _isRefreshing) return;

    _isRefreshing = true;
    _isLoading = _servers.isEmpty;
    _error = null;
    _notify();

    try {
      final servers = await _gateService.fetchServers();
      if (_disposed) return;

      _servers = servers;
      _lastUpdated = DateTime.now();
      _showingCached = false;
      _error = null;
      await _cacheService.save(servers);
      if (_disposed) return;
      await _restoreSelectedServer();
    } on VpnGateException catch (exception) {
      if (_disposed) return;
      _error = exception.message;
      if (_servers.isNotEmpty) _showingCached = true;
    } catch (_) {
      if (_disposed) return;
      _error = 'Could not refresh servers. Please try again.';
    } finally {
      if (!_disposed) {
        _isRefreshing = false;
        _isLoading = false;
        _notify();
      }
    }
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    _notify();
  }

  void clearQuery() => setQuery('');

  void setSort(ServerSort value) {
    if (_sort == value) return;
    _sort = value;
    _notify();
  }

  /// Connects to [server], switching away from any existing tunnel first.
  Future<void> connectTo(VpnServer server) async {
    if (_disposed) return;
    final attempt = ++_attempt;

    if (_connectionStatus == VpnConnectionStatus.connected ||
        _connectionStatus == VpnConnectionStatus.connecting) {
      await _openVpnService.disconnect();
      if (_disposed || attempt != _attempt) return;
    }

    _selectedServer = server;
    _connectionStatus = VpnConnectionStatus.connecting;
    _stageLabel = 'Preparing...';
    _connectionError = null;
    _traffic = VpnTraffic.empty;
    _notify();
    unawaited(_persistSelectedServer(server));

    try {
      await _requestNotificationPermission();
      final ready = await _ensureEngine();
      if (_disposed || attempt != _attempt) return;
      if (!ready) {
        _fail(_engineError ?? 'The VPN engine is not available.');
        return;
      }

      final started = await _openVpnService.connect(server);
      if (_disposed || attempt != _attempt) return;
      if (!started) {
        final isApple =
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
        _fail(
          isApple
              ? 'The VPN configuration could not start. Allow the system '
                    'prompt, or complete the Network Extension setup in '
                    'IOS_SETUP.md.'
              : 'VPN permission was denied. Tap connect to try again.',
        );
      }
    } catch (exception) {
      if (_disposed || attempt != _attempt) return;
      _fail(_friendlyConnectError(exception));
    }
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _attempt++;

    if (_connectionStatus == VpnConnectionStatus.disconnected) return;

    _connectionStatus = VpnConnectionStatus.disconnecting;
    _stageLabel = 'Disconnecting...';
    _notify();

    await _openVpnService.disconnect();

    if (_disposed) return;
    _connectionStatus = VpnConnectionStatus.disconnected;
    _stageLabel = 'Disconnected';
    _connectionError = null;
    _traffic = VpnTraffic.empty;
    _notify();
  }

  /// Reconnects the currently selected server after a failure.
  Future<void> retryConnection() async {
    final server = _selectedServer;
    if (server == null) return;
    await connectTo(server);
  }

  void dismissConnectionError() {
    _connectionError = null;
    if (_connectionStatus == VpnConnectionStatus.error) {
      _connectionStatus = VpnConnectionStatus.disconnected;
      _stageLabel = 'Disconnected';
    }
    _notify();
  }

  Future<List<String>> fetchLogs() => _openVpnService.logs();

  Future<void> _loadCache() async {
    final cache = await _cacheService.load();
    if (_disposed || cache == null || _servers.isNotEmpty) return;
    _servers = cache.servers;
    _lastUpdated = cache.savedAt;
    _showingCached = true;
    _notify();
    await _restoreSelectedServer();
  }

  Future<void> _restoreSelectedServer() async {
    if (_disposed || _selectedServer != null) return;
    try {
      final preferences = await SharedPreferences.getInstance();

      final raw = preferences.getString(_selectedServerKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final server = VpnServer.fromJson(Map<String, dynamic>.from(decoded));
          if (server.hasConfig) {
            _selectedServer = server;
            _notify();
            return;
          }
        }
      }

      // Migrate the id-only value written by older builds.
      final id = preferences.getString('selected_server_id');
      if (id == null) return;
      for (final server in _servers) {
        if (server.id == id) {
          _selectedServer = server;
          _notify();
          return;
        }
      }
    } catch (_) {
      // Restoring the last selection is a convenience only.
    }
  }

  Future<void> _persistSelectedServer(VpnServer server) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _selectedServerKey,
        jsonEncode(server.toJson()),
      );
      await preferences.remove('selected_server_id');
    } catch (_) {
      // Persistence is best effort.
    }
  }

  Future<bool> _ensureEngine() async {
    if (_engineReady) return true;
    await _initializeEngine();
    return _engineReady;
  }

  Future<void> _initializeEngine() async {
    if (_disposed) return;
    try {
      await _openVpnService.initialize();
      if (_disposed) return;
      _engineReady = true;
      _engineError = null;
    } catch (exception) {
      if (_disposed) return;
      _engineReady = false;
      _engineError = _friendlyEngineError(exception);
    }
    _notify();
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await Permission.notification.request();
    } catch (_) {
      // The VPN works without the notification permission.
    }
  }

  void _handleStage(VPNStage stage, String rawStage) {
    if (_disposed) return;
    _stageLabel = _stageText(stage);

    if (stage.isConnected) {
      _connectionStatus = VpnConnectionStatus.connected;
      _connectionError = null;
    } else if (stage == VPNStage.denied) {
      _connectionStatus = VpnConnectionStatus.error;
      _connectionError =
          'VPN permission was denied. Tap connect to show the prompt again.';
    } else if (stage == VPNStage.auth_failed) {
      _connectionStatus = VpnConnectionStatus.error;
      _connectionError =
          'The server rejected the connection. Try a different server.';
    } else if (stage == VPNStage.error) {
      _connectionStatus = VpnConnectionStatus.error;
      _connectionError = 'The connection failed. Try another server.';
      unawaited(_loadLastError());
    } else if (stage == VPNStage.disconnecting || stage == VPNStage.exiting) {
      _connectionStatus = VpnConnectionStatus.disconnecting;
    } else if (stage.isDisconnected) {
      if (_connectionStatus == VpnConnectionStatus.connected ||
          _connectionStatus == VpnConnectionStatus.disconnecting) {
        _connectionStatus = VpnConnectionStatus.disconnected;
        _traffic = VpnTraffic.empty;
      } else if (_connectionStatus == VpnConnectionStatus.connecting) {
        _connectionStatus = VpnConnectionStatus.error;
        _connectionError ??= 'The connection attempt did not complete.';
        unawaited(_loadLastError());
      }
      // Keep an existing error visible so the user can read the reason.
    } else if (stage.isConnecting) {
      _connectionStatus = VpnConnectionStatus.connecting;
    }

    _notify();
  }

  void _handleStatus(VpnStatus? status) {
    if (_disposed) return;
    _traffic = status == null
        ? VpnTraffic.empty
        : VpnTraffic.fromEngine(status);
    _notify();
  }

  Future<void> _loadLastError() async {
    try {
      final message = await _openVpnService.lastError();
      if (_disposed || message == null || message.trim().isEmpty) return;
      _connectionError = message.trim();
      _notify();
    } catch (_) {
      // Keep the generic message.
    }
  }

  void _fail(String message) {
    if (_disposed) return;
    _connectionStatus = VpnConnectionStatus.error;
    _stageLabel = 'Connection failed';
    _connectionError = message;
    _notify();
  }

  String _friendlyEngineError(Object error) {
    if (error is MissingPluginException) {
      return 'The VPN engine is not available on this device.';
    }
    if (error is PlatformException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'The VPN engine could not start (${error.code}).';
    }
    if (error is StateError) return error.message;
    return 'The VPN engine could not start on this device.';
  }

  String _friendlyConnectError(Object error) {
    if (error is MissingPluginException) {
      return 'The VPN engine is not available on this device.';
    }
    if (error is PlatformException) {
      if (error.code == 'native_libraries_not_extracted') {
        return 'Android could not load the VPN engine. Reinstall the app and try again.';
      }
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return 'Could not start the VPN (${error.code}).';
    }
    if (error is StateError) return error.message;
    return 'Could not start the VPN. Try another server.';
  }

  String _stageText(VPNStage stage) => switch (stage) {
    VPNStage.prepare => 'Waiting for VPN permission...',
    VPNStage.vpn_generate_config => 'Preparing configuration...',
    VPNStage.resolve => 'Resolving server...',
    VPNStage.tcp_connect || VPNStage.udp_connect => 'Opening tunnel...',
    VPNStage.wait_connection => 'Waiting for server...',
    VPNStage.authenticating || VPNStage.authentication => 'Authenticating...',
    VPNStage.get_config => 'Receiving configuration...',
    VPNStage.assign_ip => 'Assigning address...',
    VPNStage.add_routes => 'Configuring routes...',
    VPNStage.connecting => 'Connecting...',
    VPNStage.connected => 'Connected',
    VPNStage.reconnect => 'Reconnecting...',
    VPNStage.no_network => 'No network — waiting...',
    VPNStage.paused => 'Paused',
    VPNStage.auth_pending => 'Waiting for authentication...',
    VPNStage.disconnecting => 'Disconnecting...',
    VPNStage.exiting => 'Closing tunnel...',
    VPNStage.disconnected => 'Disconnected',
    VPNStage.denied => 'VPN permission denied',
    VPNStage.auth_failed => 'Authentication failed',
    VPNStage.error => 'Connection failed',
    VPNStage.unknown => 'Working...',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _attempt++;
    _openVpnService.dispose();
    _gateService.dispose();
    super.dispose();
  }
}
