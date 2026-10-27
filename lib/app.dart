import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'state/vpn_provider.dart';
import 'ui/screens/home_screen.dart';

class FreeVpnApp extends StatelessWidget {
  const FreeVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VpnProvider()..initialize(),
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
