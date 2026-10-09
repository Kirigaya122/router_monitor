class RouterStatistics {
  // Current traffic counters
  final int rxBytes;
  final int txBytes;
  final int rxTxBytes;
  final int errorBytes;

  // Monthly traffic counters
  final int monthRxBytes;
  final int monthTxBytes;

  // Total traffic counters
  final int totalRxBytes;
  final int totalTxBytes;
  final int totalRxTxBytes;
  final int totalErrorBytes;

  // Packet counters
  final int totalRxPackets;
  final int totalTxPackets;
  final int totalRxTxPackets;

  // Current throughput
  final double upThroughput;
  final double downThroughput;

  // Average throughput
  final double averageUpThroughput;
  final double averageDownThroughput;

  // Maximum throughput
  final double maximumUpThroughput;
  final double maximumDownThroughput;

  const RouterStatistics({
    required this.rxBytes,
    required this.txBytes,
    required this.rxTxBytes,
    required this.errorBytes,
    required this.monthRxBytes,
    required this.monthTxBytes,
    required this.totalRxBytes,
    required this.totalTxBytes,
    required this.totalRxTxBytes,
    required this.totalErrorBytes,
    required this.totalRxPackets,
    required this.totalTxPackets,
    required this.totalRxTxPackets,
    required this.upThroughput,
    required this.downThroughput,
    required this.averageUpThroughput,
    required this.averageDownThroughput,
    required this.maximumUpThroughput,
    required this.maximumDownThroughput,
  });
}

class RouterBattery {
  final int capacity;
  final int health;
  final int present;
  final int type;
  final int voltageNow;
  final int status;
  final int temperature;
  final int technology;
  final int acChargingOnline;
  final int acChargingType;
  final int acChargingStatus;
  final int usbChargingOnline;
  final int usbChargingType;
  final int usbChargingStatus;

  String get statusLabel {
    if (present == 0) return 'Battery not present';

    switch (status) {
      case 0:
        return 'Unknown error';
      case 1:
        return 'Charging';
      case 2:
        return 'Not charging';
      case 3:
        return capacity == 100 ? 'Fully charged' : 'Discharging';
      case 4:
        return 'Fully charged';
      default:
        return 'Unknown status';
    }
  }

  bool get isPresent => present == 1;

  bool get isAcChargingOnline => acChargingOnline == 1;

  bool get isUsbChargingOnline => usbChargingOnline == 1;

  // Common firmware conventions; confirm units against the UI.
  double get voltageVolts => voltageNow / 1000.0;

  double get temperatureCelsius => temperature / 10.0;

  const RouterBattery({
    required this.capacity,
    required this.health,
    required this.present,
    required this.type,
    required this.voltageNow,
    required this.status,
    required this.temperature,
    required this.technology,
    required this.acChargingOnline,
    required this.acChargingType,
    required this.acChargingStatus,
    required this.usbChargingOnline,
    required this.usbChargingType,
    required this.usbChargingStatus,
  });
}

class RouterClientDevice {
  final String macAddress;
  final String connectionType;
  final String ipAddress;
  final String name;
  final int connectionTimeSeconds;
  final int leaseRemainingSeconds;

  const RouterClientDevice({
    required this.macAddress,
    required this.connectionType,
    required this.ipAddress,
    required this.name,
    required this.connectionTimeSeconds,
    required this.leaseRemainingSeconds,
  });

  String get connectionDuration {
    final hours = connectionTimeSeconds ~/ 3600;
    final minutes = (connectionTimeSeconds % 3600) ~/ 60;
    final seconds = connectionTimeSeconds % 60;

    return '${hours}h ${minutes}m ${seconds}s';
  }

  String get leaseRemaining {
    final hours = leaseRemainingSeconds ~/ 3600;
    final minutes = (leaseRemainingSeconds % 3600) ~/ 60;

    return '${hours}h ${minutes}m';
  }
}
