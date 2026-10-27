import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../state/vpn_provider.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.status,
    required this.label,
    this.compact = false,
  });

  final VpnConnectionStatus status;
  final String label;
  final bool compact;

  static Color colorFor(VpnConnectionStatus status) => switch (status) {
    VpnConnectionStatus.connected => AppTheme.accent,
    VpnConnectionStatus.connecting ||
    VpnConnectionStatus.disconnecting => AppTheme.warning,
    VpnConnectionStatus.error => AppTheme.danger,
    VpnConnectionStatus.disconnected => AppTheme.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
