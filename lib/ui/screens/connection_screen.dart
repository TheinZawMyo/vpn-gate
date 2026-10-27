import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/vpn_server.dart';
import '../../state/vpn_provider.dart';
import '../widgets/flag_badge.dart';
import '../widgets/status_pill.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.screenGradient),
        child: SafeArea(
          child: Consumer<VpnProvider>(
            builder: (context, provider, _) {
              final server = provider.selectedServer;
              if (server == null) {
                return _NoServer(onBack: () => Navigator.of(context).pop());
              }

              return Column(
                children: [
                  _TopBar(
                    onBack: () => Navigator.of(context).pop(),
                    onLogs: () => _showLogs(context, provider),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          _StatusOrb(status: provider.connectionStatus),
                          const SizedBox(height: 22),
                          Text(
                            provider.connectionLabel,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: _statusColor(provider.connectionStatus),
                            ),
                          ),
                          if ((provider.connectionStatus ==
                                      VpnConnectionStatus.connecting ||
                                  provider.connectionStatus ==
                                      VpnConnectionStatus.disconnecting) &&
                              provider.stageLabel !=
                                  provider.connectionLabel) ...[
                            const SizedBox(height: 6),
                            Text(
                              provider.stageLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                          if (provider.connectionError != null) ...[
                            const SizedBox(height: 18),
                            _ErrorCard(
                              message: provider.connectionError!,
                              onRetry: provider.retryConnection,
                              onDismiss: provider.dismissConnectionError,
                            ),
                          ],
                          const SizedBox(height: 22),
                          _ServerCard(server: server, provider: provider),
                          const SizedBox(height: 12),
                          _TrafficCard(provider: provider),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showLogs(context, provider),
                            icon: const Icon(Icons.terminal_rounded, size: 17),
                            label: const Text('View connection log'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _ActionBar(provider: provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Color _statusColor(VpnConnectionStatus status) => switch (status) {
    VpnConnectionStatus.connected => AppTheme.accent,
    VpnConnectionStatus.connecting ||
    VpnConnectionStatus.disconnecting => AppTheme.warning,
    VpnConnectionStatus.error => AppTheme.danger,
    VpnConnectionStatus.disconnected => AppTheme.textPrimary,
  };

  void _showLogs(BuildContext context, VpnProvider provider) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.terminal_rounded,
                        size: 19,
                        color: AppTheme.accent,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Connection log',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: provider.fetchLogs(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppTheme.accent,
                          ),
                        );
                      }
                      final lines =
                          snapshot.data?.reversed.toList() ?? const <String>[];
                      if (lines.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(28),
                            child: Text(
                              'No log lines yet. The VPN engine writes them once a connection starts.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      }
                      return SelectionArea(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: lines.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            return Text(
                              lines[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.4,
                                color: AppTheme.textMuted,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onLogs});

  final VoidCallback onBack;
  final VoidCallback onLogs;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          const Expanded(
            child: Text(
              'Connection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onLogs,
            tooltip: 'Connection log',
            icon: const Icon(Icons.terminal_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _StatusOrb extends StatefulWidget {
  const _StatusOrb({required this.status});

  final VpnConnectionStatus status;

  @override
  State<_StatusOrb> createState() => _StatusOrbState();
}

class _StatusOrbState extends State<_StatusOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _StatusOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncAnimation();
  }

  void _syncAnimation() {
    final animate =
        widget.status == VpnConnectionStatus.connected ||
        widget.status == VpnConnectionStatus.connecting ||
        widget.status == VpnConnectionStatus.disconnecting;
    if (animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final color = StatusPill.colorFor(status);
    final connected = status == VpnConnectionStatus.connected;
    final active =
        connected ||
        status == VpnConnectionStatus.connecting ||
        status == VpnConnectionStatus.disconnecting;

    return SizedBox(
      width: 224,
      height: 224,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              if (active)
                for (var i = 0; i < 3; i++)
                  _PulseRing(
                    progress: (_controller.value + i / 3) % 1,
                    color: color,
                  ),
              Container(
                width: 138,
                height: 138,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: connected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.accent, Color(0xFF1A9E9A)],
                        )
                      : null,
                  color: connected ? null : AppTheme.surface,
                  border: Border.all(
                    color: color.withValues(alpha: connected ? 0.0 : 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: connected ? 0.35 : 0.12),
                      blurRadius: 40,
                      spreadRadius: connected ? 6 : 0,
                    ),
                  ],
                ),
                child: child,
              ),
            ],
          );
        },
        child: Icon(
          connected
              ? Icons.shield_rounded
              : status == VpnConnectionStatus.error
              ? Icons.priority_high_rounded
              : status == VpnConnectionStatus.connecting ||
                    status == VpnConnectionStatus.disconnecting
              ? Icons.sync_rounded
              : Icons.power_settings_new_rounded,
          size: 54,
          color: connected ? const Color(0xFF031310) : color,
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = 0.85 + progress * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: (1 - progress) * 0.35),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.server, required this.provider});

  final VpnServer server;
  final VpnProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              FlagBadge(
                countryCode: server.countryShort,
                size: 44,
                highlight: provider.isConnected,
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      server.ip,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                status: provider.connectionStatus,
                label: provider.connectionLabel,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Ping', value: Formatters.ping(server.ping)),
              _Stat(
                label: 'Bandwidth',
                value: Formatters.bandwidth(server.speed),
              ),
              _Stat(label: 'Score', value: Formatters.score(server.score)),
              _Stat(
                label: 'Sessions',
                value: Formatters.compactNumber(server.numVpnSessions),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrafficCard extends StatelessWidget {
  const _TrafficCard({required this.provider});

  final VpnProvider provider;

  @override
  Widget build(BuildContext context) {
    final traffic = provider.traffic;
    final connected = provider.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          _TrafficStat(
            icon: Icons.arrow_downward_rounded,
            label: 'Download',
            value: Formatters.bytes(traffic.bytesIn),
            detail: connected ? Formatters.speed(traffic.speedIn) : null,
            color: AppTheme.accent,
          ),
          _TrafficStat(
            icon: Icons.arrow_upward_rounded,
            label: 'Upload',
            value: Formatters.bytes(traffic.bytesOut),
            detail: connected ? Formatters.speed(traffic.speedOut) : null,
            color: AppTheme.accentSecondary,
          ),
          _TrafficStat(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: connected ? traffic.duration : '00:00:00',
            detail: connected ? 'Session time' : 'Not connected',
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  const _TrafficStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail ?? label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 17),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.provider});

  final VpnProvider provider;

  @override
  Widget build(BuildContext context) {
    final status = provider.connectionStatus;

    Widget button;
    if (status == VpnConnectionStatus.connected) {
      button = FilledButton.icon(
        onPressed: provider.disconnect,
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.danger,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.power_settings_new_rounded, size: 20),
        label: const Text('Disconnect'),
      );
    } else if (status == VpnConnectionStatus.disconnecting) {
      button = FilledButton(
        onPressed: null,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(width: 10),
            Text('Disconnecting...'),
          ],
        ),
      );
    } else if (status == VpnConnectionStatus.connecting) {
      button = OutlinedButton.icon(
        onPressed: provider.disconnect,
        icon: const Icon(Icons.close_rounded, size: 19),
        label: const Text('Cancel'),
      );
    } else if (status == VpnConnectionStatus.error) {
      button = FilledButton.icon(
        onPressed: provider.retryConnection,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text('Try again'),
      );
    } else {
      button = FilledButton.icon(
        onPressed: provider.retryConnection,
        icon: const Icon(Icons.power_settings_new_rounded, size: 20),
        label: const Text('Connect'),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.92),
        border: const Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: double.infinity, child: button),
          const SizedBox(height: 8),
          const Text(
            'Traffic is routed through a volunteer-run OpenVPN server.',
            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NoServer extends StatelessWidget {
  const _NoServer({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dns_outlined, size: 36, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No server selected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}
