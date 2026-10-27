import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String developerName = 'Bo Thein';

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        title: AppConfig.appName,
        text:
            '${AppConfig.appName} — connect with free public VPN Gate servers using OpenVPN.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About & legal')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const _AboutCard(
              icon: Icons.shield_rounded,
              title: AppConfig.appName,
              body: 'Developed by $developerName',
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.ios_share_rounded,
              title: 'Share app',
              subtitle: 'Tell someone about Free VPN',
              onTap: _shareApp,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy policy',
              subtitle: 'What the app stores and what VPN servers may see',
              onTap: () => _showDocument(
                context,
                title: 'Privacy policy',
                sections: _privacySections,
              ),
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.gavel_rounded,
              title: 'Terms of service',
              subtitle: 'Rules and limitations for using the app',
              onTap: () => _showDocument(
                context,
                title: 'Terms of service',
                sections: _termsSections,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Free public VPN servers are operated by volunteers. Avoid using them for sensitive accounts or private information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDocument(
    BuildContext context, {
    required String title,
    required List<(String, String)> sections,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LegalDocumentScreen(title: title, sections: sections),
      ),
    );
  }
}

class _LegalDocumentScreen extends StatelessWidget {
  const _LegalDocumentScreen({required this.title, required this.sections});

  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Developer: ${AboutScreen.developerName}',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            for (final (heading, body) in sections) ...[
              Text(
                heading,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                body,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppTheme.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const List<(String, String)> _privacySections = [
  (
    'Information the app handles',
    'Free VPN does not require an account and does not include ads or analytics. It requests the public server list from VPN Gate. The app stores the downloaded server list and your last selected server on your device so it can restore them later. Connection duration, traffic totals, and VPN engine logs are used locally to show connection status and troubleshooting details.',
  ),
  (
    'VPN connections and third parties',
    'When you connect, your network traffic is routed through the volunteer operated VPN server you select. That server and the networks between it and your destination are outside the developer’s control and may observe connection details or activity. VPN Gate provides the server list and has its own practices. Review its information at vpngate.net before connecting.',
  ),
  (
    'Sharing and retention',
    'The app does not send your browsing history, traffic counters, or connection logs to the developer. The server cache, selected server, and VPN engine logs remain on your device and may be removed by clearing app data or uninstalling the app. Your use of the operating system share sheet is handled by the app you choose.',
  ),
  (
    'Changes and contact',
    'This policy may be updated when the app changes. The developer name shown here is Bo Thein. No support email or public policy website is configured in this project yet.',
  ),
];

const List<(String, String)> _termsSections = [
  (
    'Acceptable use',
    'Use Free VPN only where lawful and in a way that respects the rights, rules, and network policies that apply to you. You are responsible for your activity and for checking local requirements before connecting.',
  ),
  (
    'Volunteer servers and availability',
    'Servers are supplied by independent volunteers through VPN Gate. They can be slow, unavailable, changed, or operated under conditions the developer cannot verify. The app and servers are provided without a promise of uninterrupted service, security, anonymity, or fitness for a particular purpose.',
  ),
  (
    'Your responsibility',
    'Do not rely on public volunteer servers for banking, sensitive accounts, confidential communications, or other high risk activity. You are responsible for protecting your devices and information and for deciding whether a server is appropriate for your use.',
  ),
  (
    'Third party software and services',
    'The app uses OpenVPN software and obtains server information from VPN Gate. Those projects and server operators are independent of the developer and may have separate terms. Their terms and licenses continue to apply to their services and software.',
  ),
  (
    'Changes to these terms',
    'These terms may be updated as the app changes. Continued use after an update means you agree to the updated terms to the extent permitted by applicable law.',
  ),
];
