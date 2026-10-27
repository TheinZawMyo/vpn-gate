// ignore_for_file: avoid_print

import 'package:free_vpn/core/formatters.dart';
import 'package:free_vpn/data/services/vpn_gate_service.dart';

Future<void> main() async {
  final service = VpnGateService();
  final stopwatch = Stopwatch()..start();
  try {
    final servers = await service.fetchServers();
    stopwatch.stop();
    print(
      'Fetched ${servers.length} servers in ${stopwatch.elapsedMilliseconds}ms',
    );
    for (final server in servers.take(3)) {
      print(
        '${server.countryLong} ${Formatters.ping(server.ping)} '
        '${Formatters.bandwidth(server.speed)} config=${server.openVpnConfigData.length}b',
      );
    }
    final bad = servers.where((s) => !s.openVpnConfigData.contains('remote '));
    print('Servers without a remote line: ${bad.length}');
  } finally {
    service.dispose();
  }
}
