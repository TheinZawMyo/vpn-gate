import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../models/vpn_server.dart';

/// Raised when the VPN Gate list cannot be fetched or parsed.
class VpnGateException implements Exception {
  const VpnGateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches and parses the public VPN Gate server list.
class VpnGateService {
  VpnGateService({http.Client? client, this.timeout = AppConfig.requestTimeout})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final Csv _csv = Csv(autoDetect: false, skipEmptyLines: true);

  Uri get endpoint => Uri.parse(AppConfig.vpnGateEndpoint);

  /// Downloads the CSV, decodes the Base64 OpenVPN configs and returns the
  /// usable servers. Throws [VpnGateException] with a user-friendly message.
  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await _client
          .get(
            endpoint,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (compatible; FreeVPN/1.0)',
              'Accept': 'text/csv,text/plain,*/*',
            },
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw VpnGateException(
          'VPN Gate returned HTTP ${response.statusCode}. Try again shortly.',
        );
      }

      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final servers = parseCsv(body);

      if (servers.isEmpty) {
        throw const VpnGateException(
          'VPN Gate returned no usable servers. Please retry in a moment.',
        );
      }
      return servers;
    } on VpnGateException {
      rethrow;
    } on TimeoutException {
      throw const VpnGateException(
        'The request timed out. Check your connection and retry.',
      );
    } on SocketException {
      throw const VpnGateException(
        'No internet connection. Check your network and retry.',
      );
    } on http.ClientException {
      throw const VpnGateException(
        'Could not reach VPN Gate. Check your connection and retry.',
      );
    } on FormatException {
      throw const VpnGateException(
        'VPN Gate sent an unexpected response. Please retry.',
      );
    } catch (_) {
      throw const VpnGateException(
        'Something went wrong while loading servers. Please retry.',
      );
    }
  }

  /// Parses the raw CSV body. Exposed for tests.
  List<VpnServer> parseCsv(String content) {
    final rows = _csv.decode(content);
    final servers = <VpnServer>[];
    final seen = <String>{};

    for (final row in rows) {
      final server = VpnServer.tryFromCsvRow(row);
      if (server == null || !server.hasConfig) continue;
      if (seen.add(server.id)) servers.add(server);
    }

    return servers;
  }

  void dispose() => _client.close();
}
