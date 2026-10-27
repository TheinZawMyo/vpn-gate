import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/vpn_server.dart';

class ServerCache {
  const ServerCache({required this.servers, required this.savedAt});

  final List<VpnServer> servers;
  final DateTime savedAt;
}

/// Stores the last successful server list so the app still works offline.
class VpnCacheService {
  static const int _version = 1;
  static const String _fileName = 'vpn_servers_cache.json';

  Future<File?> _cacheFile() async {
    try {
      final directory = await getApplicationSupportDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return File('${directory.path}/$_fileName');
    } catch (_) {
      return null;
    }
  }

  Future<ServerCache?> load() async {
    try {
      final file = await _cacheFile();
      if (file == null || !await file.exists()) return null;

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['version'] != _version) return null;

      final rawServers = decoded['servers'];
      final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
      if (rawServers is! List || savedAt == null) return null;

      final servers = <VpnServer>[];
      for (final raw in rawServers) {
        if (raw is! Map) continue;
        final server = VpnServer.fromJson(Map<String, dynamic>.from(raw));
        if (server.hasConfig) servers.add(server);
      }
      if (servers.isEmpty) return null;

      return ServerCache(servers: servers, savedAt: savedAt);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(List<VpnServer> servers) async {
    if (servers.isEmpty) return;
    try {
      final file = await _cacheFile();
      if (file == null) return;
      final payload = jsonEncode({
        'version': _version,
        'savedAt': DateTime.now().toIso8601String(),
        'servers': [for (final server in servers) server.toJson()],
      });
      await file.writeAsString(payload, flush: true);
    } catch (_) {
      // The cache is best effort; a failed write must never break the app.
    }
  }
}
