import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_vpn/core/app_theme.dart';
import 'package:free_vpn/data/models/vpn_server.dart';
import 'package:free_vpn/ui/widgets/server_tile.dart';

void main() {
  const server = VpnServer(
    hostName: 'server-1',
    ip: '10.0.0.2',
    countryLong: 'Japan',
    countryShort: 'JP',
    score: 1940463,
    ping: 25,
    speed: 5000000,
    openVpnConfigData: 'client\n',
  );

  testWidgets('shows country, host, ping and bandwidth', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: ServerTile(server: server, onTap: () => tapped = true),
          ),
        ),
      ),
    );

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('server-1 · 10.0.0.2'), findsOneWidget);
    expect(find.text('25 ms'), findsOneWidget);
    expect(find.text('5.0 Mbps'), findsOneWidget);

    await tester.tap(find.byType(ServerTile));
    expect(tapped, isTrue);
  });
}
