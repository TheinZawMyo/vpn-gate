import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpn/core/formatters.dart';

void main() {
  test('creates flag emojis from ISO country codes', () {
    expect(Formatters.flagEmoji('JP'), '🇯🇵');
    expect(Formatters.flagEmoji('us'), '🇺🇸');
    expect(Formatters.flagEmoji('X'), '🌐');
    expect(Formatters.flagEmoji(''), '🌐');
  });

  test('formats bytes with binary units', () {
    expect(Formatters.bytes(0), '0 B');
    expect(Formatters.bytes(512), '512 B');
    expect(Formatters.bytes(1536), '1.5 KB');
    expect(Formatters.bytes(1048576), '1 MB');
    expect(Formatters.bytes(1073741824), '1 GB');
  });

  test('formats VPN Gate bandwidth', () {
    expect(Formatters.bandwidth(0), 'Unknown');
    expect(Formatters.bandwidth(5000000), '5.0 Mbps');
    expect(Formatters.bandwidth(206394681), '206.4 Mbps');
    expect(Formatters.bandwidth(1500000000), '1.5 Gbps');
  });

  test('formats speeds, pings and scores', () {
    expect(Formatters.speed(1536), '1.5 KB/s');
    expect(Formatters.ping(0), '—');
    expect(Formatters.ping(24), '24 ms');
    expect(Formatters.score(1940463), '1.9M');
  });
}
