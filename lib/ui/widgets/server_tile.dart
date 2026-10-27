import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../data/models/vpn_server.dart';
import 'flag_badge.dart';

class ServerTile extends StatelessWidget {
  const ServerTile({
    super.key,
    required this.server,
    required this.onTap,
    this.isSelected = false,
    this.isActive = false,
  });

  final VpnServer server;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final pingColor = _pingColor(server.ping);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceHigh : AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? AppTheme.accent.withValues(alpha: 0.65)
                  : isSelected
                  ? AppTheme.accentSecondary.withValues(alpha: 0.45)
                  : AppTheme.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              FlagBadge(
                countryCode: server.countryShort,
                size: 46,
                highlight: isActive,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            server.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          server.countryShort,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.bolt_rounded,
                            size: 15,
                            color: AppTheme.accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${server.hostName} · ${server.ip}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _Metric(
                          icon: Icons.network_ping_rounded,
                          label: Formatters.ping(server.ping),
                          color: pingColor,
                        ),
                        const SizedBox(width: 12),
                        _Metric(
                          icon: Icons.speed_rounded,
                          label: Formatters.bandwidth(server.speed),
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isActive
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isActive ? AppTheme.accent : AppTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _pingColor(int ping) {
    if (ping <= 0) return AppTheme.textMuted;
    if (ping <= 60) return AppTheme.accent;
    if (ping <= 140) return AppTheme.warning;
    return AppTheme.danger;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
