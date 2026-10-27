import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpn/data/models/vpn_server.dart';
import 'package:free_vpn/data/services/vpn_cache_service.dart';
import 'package:free_vpn/data/services/vpn_gate_service.dart';
import 'package:free_vpn/state/vpn_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGateService extends VpnGateService {
  FakeGateService(this.servers);

  final List<VpnServer> servers;

  @override
  Future<List<VpnServer>> fetchServers() async => servers;
}

class FakeCacheService extends VpnCacheService {
  @override
  Future<ServerCache?> load() async => null;

  @override
  Future<void> save(List<VpnServer> servers) async {}
}

VpnServer server({
  required String host,
  required String country,
  required String code,
  required int score,
  required int ping,
  required int speed,
}) {
  return VpnServer(
    hostName: host,
    ip: '10.0.0.1',
    countryLong: country,
    countryShort: code,
    score: score,
    ping: ping,
    speed: speed,
    openVpnConfigData: 'client\n',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late VpnProvider provider;

  setUp(() {
    provider = VpnProvider(
      gateService: FakeGateService([
        server(
          host: 'japan-1',
          country: 'Japan',
          code: 'JP',
          score: 300,
          ping: 80,
          speed: 100,
        ),
        server(
          host: 'korea-1',
          country: 'Korea',
          code: 'KR',
          score: 100,
          ping: 10,
          speed: 500,
        ),
        server(
          host: 'us-1',
          country: 'United States',
          code: 'US',
          score: 200,
          ping: 0,
          speed: 300,
        ),
      ]),
      cacheService: FakeCacheService(),
    );
  });

  tearDown(() => provider.dispose());

  Future<VpnProvider> loaded() async {
    await provider.refreshServers();
    return provider;
  }

  test('sorts servers by recommendation score', () async {
    final loadedProvider = await loaded();
    expect(loadedProvider.visibleServers.map((server) => server.hostName), [
      'japan-1',
      'us-1',
      'korea-1',
    ]);
  });

  test('sorts by ping and pushes unknown pings to the end', () async {
    final loadedProvider = await loaded();
    loadedProvider.setSort(ServerSort.fastest);
    expect(loadedProvider.visibleServers.map((server) => server.hostName), [
      'korea-1',
      'japan-1',
      'us-1',
    ]);
  });

  test('sorts by bandwidth', () async {
    final loadedProvider = await loaded();
    loadedProvider.setSort(ServerSort.fastestSpeed);
    expect(loadedProvider.visibleServers.map((server) => server.hostName), [
      'korea-1',
      'us-1',
      'japan-1',
    ]);
  });

  test('filters by country name, code, host or IP', () async {
    final loadedProvider = await loaded();

    loadedProvider.setQuery('kor');
    expect(loadedProvider.visibleServers.single.hostName, 'korea-1');

    loadedProvider.setQuery('jp');
    expect(loadedProvider.visibleServers.single.hostName, 'japan-1');

    loadedProvider.setQuery('10.0.0.1');
    expect(loadedProvider.visibleServers, hasLength(3));

    loadedProvider.setQuery('nothing-here');
    expect(loadedProvider.visibleServers, isEmpty);
  });
}
