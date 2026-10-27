import 'dart:convert';

/// A single free OpenVPN server from the VPN Gate API.
class VpnServer {
  const VpnServer({
    required this.hostName,
    required this.ip,
    required this.countryLong,
    required this.countryShort,
    required this.score,
    required this.ping,
    required this.speed,
    required this.openVpnConfigData,
    this.numVpnSessions = 0,
    this.uptime = 0,
    this.totalUsers = 0,
    this.totalTraffic = 0,
    this.logType = '',
    this.operator = '',
    this.message = '',
  });

  final String hostName;
  final String ip;
  final String countryLong;
  final String countryShort;
  final int score;
  final int ping;
  final int speed;
  final int numVpnSessions;
  final int uptime;
  final int totalUsers;
  final int totalTraffic;
  final String logType;
  final String operator;
  final String message;

  /// Decoded contents of the `.ovpn` configuration file.
  final String openVpnConfigData;

  /// Stable identity for selection and list keys.
  String get id => '$hostName@$ip';

  /// Country name, falling back to the host name for unknown locations.
  String get displayName =>
      countryLong.trim().isEmpty ? hostName : countryLong.trim();

  bool get hasConfig => openVpnConfigData.trim().isNotEmpty;

  bool get isUnknownPing => ping <= 0;

  /// Parses one row of the VPN Gate CSV.
  ///
  /// Returns `null` for the header, comment rows and entries whose OpenVPN
  /// configuration is missing or corrupt.
  static VpnServer? tryFromCsvRow(List<dynamic> row) {
    if (row.length < 15) return null;

    final hostName = _text(row[0]);
    final ip = _text(row[1]);
    if (hostName.isEmpty || ip.isEmpty || hostName == 'HostName') return null;
    if (hostName.startsWith('*') || hostName.startsWith('#')) return null;

    final config = _decodeConfig(_text(row[14]));
    if (config == null || config.trim().isEmpty) return null;

    return VpnServer(
      hostName: hostName,
      ip: ip,
      score: _int(row[2]),
      ping: _int(row[3]),
      speed: _int(row[4]),
      countryLong: _text(row[5]),
      countryShort: _text(row[6]),
      numVpnSessions: _int(row[7]),
      uptime: _int(row[8]),
      totalUsers: _int(row[9]),
      totalTraffic: _int(row[10]),
      logType: _text(row[11]),
      operator: _text(row[12]),
      message: _text(row[13]),
      openVpnConfigData: config,
    );
  }

  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      hostName: json['hostName'] as String? ?? '',
      ip: json['ip'] as String? ?? '',
      countryLong: json['countryLong'] as String? ?? '',
      countryShort: json['countryShort'] as String? ?? '',
      score: _asInt(json['score']),
      ping: _asInt(json['ping']),
      speed: _asInt(json['speed']),
      numVpnSessions: _asInt(json['numVpnSessions']),
      uptime: _asInt(json['uptime']),
      totalUsers: _asInt(json['totalUsers']),
      totalTraffic: _asInt(json['totalTraffic']),
      logType: json['logType'] as String? ?? '',
      operator: json['operator'] as String? ?? '',
      message: json['message'] as String? ?? '',
      openVpnConfigData: json['openVpnConfigData'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'hostName': hostName,
    'ip': ip,
    'countryLong': countryLong,
    'countryShort': countryShort,
    'score': score,
    'ping': ping,
    'speed': speed,
    'numVpnSessions': numVpnSessions,
    'uptime': uptime,
    'totalUsers': totalUsers,
    'totalTraffic': totalTraffic,
    'logType': logType,
    'operator': operator,
    'message': message,
    'openVpnConfigData': openVpnConfigData,
  };

  static String _text(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) => _asInt(value);

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String? _decodeConfig(String encoded) {
    if (encoded.isEmpty) return null;
    try {
      final normalized = encoded.replaceAll(RegExp(r'\s+'), '');
      if (normalized.isEmpty) return null;
      final padded = normalized.padRight(
        normalized.length + (4 - normalized.length % 4) % 4,
        '=',
      );
      final bytes = base64.decode(padded);
      return utf8.decode(bytes, allowMalformed: true);
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) => other is VpnServer && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
