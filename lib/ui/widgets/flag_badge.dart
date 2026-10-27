import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';

class FlagBadge extends StatelessWidget {
  const FlagBadge({
    super.key,
    required this.countryCode,
    this.size = 46,
    this.highlight = false,
  });

  final String countryCode;
  final double size;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceHigh,
        border: Border.all(
          color: highlight ? AppTheme.accent : AppTheme.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.22),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        Formatters.flagEmoji(countryCode),
        style: TextStyle(fontSize: size * 0.46),
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}
