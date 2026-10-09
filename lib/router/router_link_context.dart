import './router_utils/router_text_decoder.dart';

class RouterLinkContext {
  final int systemMode;
  final int dataMode;
  final int rssi;
  final int registrationStatus;
  final String networkName;
  final int roaming;
  final String roamingNetworkName;
  final int roamingStatus;
  final int connectionStatus;
  final String ipv4Address;

  const RouterLinkContext({
    required this.systemMode,
    required this.dataMode,
    required this.rssi,
    required this.registrationStatus,
    required this.networkName,
    required this.roamingStatus,
    required this.connectionStatus,
    required this.ipv4Address,
    required this.roaming,
    required this.roamingNetworkName,
  });

  String get networkMode {
    switch (systemMode) {
      case 0:
        return 'No Service';
      case 1:
        if (dataMode != 1 && dataMode != 2 && dataMode != 16) {
          return '3G';
        }
        return '2G';
      case 2:
        return 'LTE';
      case 3:
        return '4G+';
      default:
        return 'Unknown';
    }
  }

  int? get signalDbm {
    switch (systemMode) {
      case 0:
        return null;
      case 1:
        final offset = (dataMode != 1 && dataMode != 2 && dataMode != 16)
            ? 121
            : 111;
        return rssi - offset;
      case 2:
      case 3:
        return rssi - 141;
      default:
        return null;
    }
  }

  int get signalBars {
    if (systemMode == 0) return 0;

    if (systemMode == 1) {
      final is3G = dataMode != 1 && dataMode != 2 && dataMode != 16;

      if (is3G) {
        if (rssi < 22) return 0;
        if (rssi < 27) return 1;
        if (rssi < 36) return 2;
        return 3;
      }

      if (rssi < 6) return 0;
      if (rssi < 12) return 1;
      if (rssi < 24) return 2;
      return 3;
    }

    if (systemMode == 2 || systemMode == 3) {
      if (rssi <= 21) return 0;
      if (rssi <= 26) return 1;
      if (rssi < 31) return 2;
      return 3;
    }

    return 0;
  }

  String get connectionStatusLabel {
    switch (connectionStatus) {
      case 0:
      case 10:
        return 'Disconnected';
      case 1:
        return 'Connected';
      case 2:
        return 'Connecting';
      default:
        return 'Unknown';
    }
  }

  String get networkOperator {
    final selectedName = roaming == 1 ? roamingNetworkName : networkName;

    if (selectedName.startsWith('80')) {
      return RouterTextDecoder.decode(selectedName.substring(2));
    }

    return selectedName;
  }

  bool get isRoaming => roamingStatus == 1;

  bool get isConnected => connectionStatus == 1;

  bool get isRegistered => registrationStatus == 1;
}
