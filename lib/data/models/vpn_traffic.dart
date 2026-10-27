import 'package:openvpn_flutter/openvpn_flutter.dart';

/// Platform-independent traffic snapshot for the current tunnel.
class VpnTraffic {
  const VpnTraffic({
    this.duration = '00:00:00',
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.speedIn = 0,
    this.speedOut = 0,
    this.connectedOn,
  });

  final String duration;
  final int bytesIn;
  final int bytesOut;

  /// Bytes per second.
  final int speedIn;
  final int speedOut;
  final DateTime? connectedOn;

  static const VpnTraffic empty = VpnTraffic();

  factory VpnTraffic.fromEngine(VpnStatus status) {
    return VpnTraffic(
      duration: status.duration ?? '00:00:00',
      bytesIn: int.tryParse(status.byteIn ?? '') ?? 0,
      bytesOut: int.tryParse(status.byteOut ?? '') ?? 0,
      speedIn: status.speedIn ?? 0,
      speedOut: status.speedOut ?? 0,
      connectedOn: status.connectedOn,
    );
  }
}
