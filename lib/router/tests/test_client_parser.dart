import '../parsers/router_clients_parser.dart';

void main() {
  const xml = '''
  <?xml version="1.0" encoding="utf-8"?>
  <RGW>
    <clients_info>
      <active_clients_num>2</active_clients_num>
      <active_lan_clients_num>0</active_lan_clients_num>
      <active_usb_clients_num>0</active_usb_clients_num>
      <wifi_total_num>2</wifi_total_num>
      <active_wifi_ssid1_num>2</active_wifi_ssid1_num>
      <active_wifi_ssid2_num>0</active_wifi_ssid2_num>
      <active_wifi_ssid3_num>0</active_wifi_ssid3_num>
      <active_wifi_ssid4_num>0</active_wifi_ssid4_num>
      <active_24g_wifi_clients_num>2</active_24g_wifi_clients_num>
      <active_wifi_5g_ssid1_num>0</active_wifi_5g_ssid1_num>
      <active_wifi_5g_ssid2_num>0</active_wifi_5g_ssid2_num>
      <active_wifi_5g_ssid3_num>0</active_wifi_5g_ssid3_num>
      <active_wifi_5g_ssid4_num>0</active_wifi_5g_ssid4_num>
      <active_5g_wifi_clients_num>0</active_5g_wifi_clients_num>
    </clients_info>
  </RGW>
  ''';

  final clients = RouterClients.fromXml(xml);

  print('Active clients: ${clients.activeClients}');
  print('Wi-Fi clients: ${clients.totalWifiClients}');
  print('2.4 GHz clients: ${clients.active24gWifiClients}');
  print('5 GHz clients: ${clients.active5gWifiClients}');
}
