import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/vpn_server.dart';
import '../../state/vpn_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/server_tile.dart';
import '../widgets/status_pill.dart';
import 'connection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openServer(VpnProvider provider, VpnServer server) {
    final sameServer = provider.selectedServer?.id == server.id;
    final alreadyActive =
        sameServer && (provider.isConnected || provider.isBusy);

    if (!alreadyActive) {
      provider.connectTo(server);
    }
    _openConnection(provider);
  }

  void _openConnection(VpnProvider provider) {
    if (provider.selectedServer == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ConnectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          bottom: false,
          child: Consumer<VpnProvider>(
            builder: (context, provider, _) {
              return RefreshIndicator(
                onRefresh: provider.refreshServers,
                color: AppTheme.accent,
                backgroundColor: AppTheme.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(provider: provider)),
                    if (provider.selectedServer != null)
                      SliverToBoxAdapter(
                        child: _ConnectionStrip(
                          provider: provider,
                          onTap: () => _openConnection(provider),
                        ),
                      ),
                    if (provider.engineError != null)
                      SliverToBoxAdapter(
                        child: _Banner(
                          icon: Icons.warning_amber_rounded,
                          color: AppTheme.danger,
                          text: provider.engineError!,
                        ),
                      ),
                    if (provider.showingCached && provider.error == null)
                      SliverToBoxAdapter(
                        child: _Banner(
                          icon: Icons.wifi_off_rounded,
                          color: AppTheme.warning,
                          text:
                              'Showing saved servers from ${Formatters.relativeTime(provider.lastUpdated)}.',
                          actionLabel: 'Refresh',
                          onAction: provider.refreshServers,
                        ),
                      ),
                    if (provider.error != null && provider.servers.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _Banner(
                          icon: Icons.cloud_off_rounded,
                          color: AppTheme.danger,
                          text: provider.error!,
                          actionLabel: 'Retry',
                          onAction: provider.refreshServers,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _SearchAndSort(
                        controller: _searchController,
                        provider: provider,
                      ),
                    ),
                    ..._contentSlivers(provider),
                    const SliverToBoxAdapter(child: _Footer()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(VpnProvider provider) {
    if (provider.isLoading && provider.servers.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppTheme.accent,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading free servers...',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (provider.error != null && provider.servers.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load servers',
            message: provider.error!,
            actionLabel: 'Try again',
            onAction: provider.refreshServers,
          ),
        ),
      ];
    }

    final servers = provider.visibleServers;
    if (servers.isEmpty) {
      final hasQuery = provider.query.trim().isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: hasQuery ? Icons.search_off_rounded : Icons.dns_outlined,
            title: hasQuery ? 'No matching servers' : 'No servers available',
            message: hasQuery
                ? 'No country, host or IP matches "${provider.query}".'
                : 'VPN Gate did not return any usable servers. Pull to refresh.',
            actionLabel: hasQuery ? 'Clear search' : 'Refresh',
            onAction: hasQuery
                ? () {
                    _searchController.clear();
                    provider.clearQuery();
                  }
                : provider.refreshServers,
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              Text(
                '${servers.length} ${servers.length == 1 ? 'server' : 'servers'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Updated ${Formatters.relativeTime(provider.lastUpdated)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: servers.length,
          itemBuilder: (context, index) {
            final server = servers[index];
            final selected = provider.selectedServer?.id == server.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ServerTile(
                server: server,
                isSelected: selected,
                isActive: selected && provider.isConnected,
                onTap: () => _openServer(provider, server),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final VpnProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.22),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF04140F),
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConfig.appName,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'VPN Gate · OpenVPN',
                  style: TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh servers',
            onPressed: provider.isRefreshing ? null : provider.refreshServers,
            icon: provider.isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.provider, required this.onTap});

  final VpnProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final server = provider.selectedServer;
    if (server == null) return const SizedBox.shrink();

    final subtitle = switch (provider.connectionStatus) {
      VpnConnectionStatus.connected =>
        'Session ${provider.traffic.duration} · ${Formatters.bytes(provider.traffic.bytesIn + provider.traffic.bytesOut)}',
      VpnConnectionStatus.connecting ||
      VpnConnectionStatus.disconnecting => provider.stageLabel,
      VpnConnectionStatus.error => provider.connectionError ?? 'Tap to view',
      VpnConnectionStatus.disconnected => 'Tap to connect',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accent.withValues(alpha: 0.10),
                  AppTheme.accentSecondary.withValues(alpha: 0.06),
                ],
              ),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.25),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                StatusPill(
                  status: provider.connectionStatus,
                  label: provider.connectionLabel,
                  compact: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchAndSort extends StatelessWidget {
  const _SearchAndSort({required this.controller, required this.provider});

  final TextEditingController controller;
  final VpnProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasQuery = provider.query.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: provider.setQuery,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search country, host or IP',
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: hasQuery
                  ? IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: () {
                        controller.clear();
                        provider.clearQuery();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ServerSort.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sort = ServerSort.values[index];
                final selected = provider.sort == sort;
                return ChoiceChip(
                  label: Text(sort.label),
                  selected: selected,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => provider.setSort(sort),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        children: [
          const Icon(Icons.public_rounded, size: 18, color: AppTheme.textMuted),
          const SizedBox(height: 8),
          Text(
            AppConfig.vpnGateAttribution,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Free public servers are donated by volunteers. Avoid signing in to sensitive accounts or sending private data while connected.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
