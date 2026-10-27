/// Small presentation helpers shared by the UI.
class Formatters {
  Formatters._();

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Converts an ISO 3166-1 alpha-2 country code to its flag emoji.
  static String flagEmoji(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2 ||
        code.codeUnitAt(0) < 65 ||
        code.codeUnitAt(0) > 90 ||
        code.codeUnitAt(1) < 65 ||
        code.codeUnitAt(1) > 90) {
      return '🌐';
    }
    const base = 0x1F1E6;
    return String.fromCharCodes([
      base + (code.codeUnitAt(0) - 65),
      base + (code.codeUnitAt(1) - 65),
    ]);
  }

  /// Formats a byte count with binary units.
  static String bytes(int value) {
    if (value <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = value.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    final digits = unit == 0 ? 0 : (size >= 100 ? 0 : (size >= 10 ? 1 : 2));
    var text = size.toStringAsFixed(digits);
    if (text.contains('.')) {
      text = text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return '$text ${units[unit]}';
  }

  /// Formats bytes per second as a transfer rate.
  static String speed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${bytes(bytesPerSecond)}/s';
  }

  /// Formats the server bandwidth reported by VPN Gate (bits per second).
  static String bandwidth(int bitsPerSecond) {
    if (bitsPerSecond <= 0) return 'Unknown';
    if (bitsPerSecond >= 1000000000) {
      return '${(bitsPerSecond / 1000000000).toStringAsFixed(1)} Gbps';
    }
    if (bitsPerSecond >= 1000000) {
      return '${(bitsPerSecond / 1000000).toStringAsFixed(1)} Mbps';
    }
    if (bitsPerSecond >= 1000) {
      return '${(bitsPerSecond / 1000).toStringAsFixed(0)} Kbps';
    }
    return '$bitsPerSecond bps';
  }

  static String ping(int milliseconds) {
    if (milliseconds <= 0) return '—';
    return '$milliseconds ms';
  }

  static String score(int value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  static String compactNumber(int value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  static String relativeTime(DateTime? time) {
    if (time == null) return 'Never';
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 45) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.day} ${_months[time.month - 1]}';
  }
}
