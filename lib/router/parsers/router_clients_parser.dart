import 'package:xml/xml.dart';

class RouterClients {
  final int activeClients;
  final int activeLanClients;
  final int activeUsbClients;
  final int totalWifiClients;
  final int active24gWifiClients;
  final int ssid1Clients;
  final int ssid2Clients;
  final int ssid3Clients;
  final int ssid4Clients;
  final int ssid1_5gClients;
  final int ssid2_5gClients;
  final int ssid3_5gClients;
  final int ssid4_5gClients;

  const RouterClients({
    required this.activeClients,
    required this.activeLanClients,
    required this.activeUsbClients,
    required this.totalWifiClients,
    required this.active24gWifiClients,
    required this.ssid1Clients,
    required this.ssid2Clients,
    required this.ssid3Clients,
    required this.ssid4Clients,
    required this.ssid1_5gClients,
    required this.ssid2_5gClients,
    required this.ssid3_5gClients,
    required this.ssid4_5gClients,
  });

  static RouterClients fromXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    int readInt(String tag) {
      final text = document.findAllElements(tag).firstOrNull?.innerText.trim();

      return int.tryParse(text ?? '') ?? 0;
    }

    return RouterClients(
      activeClients: readInt('active_clients_num'),
      activeLanClients: readInt('active_lan_clients_num'),
      activeUsbClients: readInt('active_usb_clients_num'),
      totalWifiClients: readInt('wifi_total_num'),
      active24gWifiClients: readInt('active_24g_wifi_clients_num'),
      ssid1Clients: readInt('active_wifi_ssid1_num'),
      ssid2Clients: readInt('active_wifi_ssid2_num'),
      ssid3Clients: readInt('active_wifi_ssid3_num'),
      ssid4Clients: readInt('active_wifi_ssid4_num'),
      ssid1_5gClients: readInt('active_wifi_5g_ssid1_num'),
      ssid2_5gClients: readInt('active_wifi_5g_ssid2_num'),
      ssid3_5gClients: readInt('active_wifi_5g_ssid3_num'),
      ssid4_5gClients: readInt('active_wifi_5g_ssid4_num'),
    );
  }
}
