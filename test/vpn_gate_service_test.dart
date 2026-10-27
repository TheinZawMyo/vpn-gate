import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpn/data/services/vpn_gate_service.dart';

void main() {
  final service = VpnGateService();

  tearDownAll(service.dispose);

  String encodeConfig(String value) => base64.encode(utf8.encode(value));

  String buildCsv(List<String> rows) {
    return [
      '*vpn_servers',
      '#HostName,IP,Score,Ping,Speed,CountryLong,CountryShort,NumVpnSessions,'
          'Uptime,TotalUsers,TotalTraffic,LogType,Operator,Message,'
          'OpenVPN_ConfigData_Base64',
      ...rows,
      '*',
      '',
    ].join('\r\n');
  }

  test('parses servers, decodes the OpenVPN config and skips bad rows', () {
    final config = '# test\nclient\ndev tun\nremote 1.2.3.4 443\n';
    final csv = buildCsv([
      'server-1,1.2.3.4,1940463,13,206394681,Japan,JP,74,1000,1977,'
          '1198674,2weeks,Owner,,${encodeConfig(config)}',
      'broken,5.6.7.8,10,20,30,Broken,BR,1,1,1,1,2weeks,Owner,,not-base64!',
    ]);

    final servers = service.parseCsv(csv);

    expect(servers, hasLength(1));
    final server = servers.single;
    expect(server.hostName, 'server-1');
    expect(server.ip, '1.2.3.4');
    expect(server.countryLong, 'Japan');
    expect(server.countryShort, 'JP');
    expect(server.score, 1940463);
    expect(server.ping, 13);
    expect(server.speed, 206394681);
    expect(server.openVpnConfigData, contains('remote 1.2.3.4 443'));
    expect(server.id, 'server-1@1.2.3.4');
  });

  test('ignores comment lines, the header and the terminator', () {
    final config = encodeConfig('client\n');
    final csv = buildCsv([
      'host,9.9.9.9,1,1,1,Country,CC,1,1,1,1,2weeks,Owner,,$config',
    ]);

    final servers = service.parseCsv(csv);

    expect(servers, hasLength(1));
    expect(servers.single.countryLong, 'Country');
  });

  test('returns an empty list when there are no usable rows', () {
    expect(service.parseCsv('*vpn_servers\r\n*\r\n'), isEmpty);
    expect(service.parseCsv(''), isEmpty);
  });
}
