import 'package:xml/xml.dart';

import '../router_link_context.dart';

class RouterLinkContextParser {
  static RouterLinkContext parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    String readText(String tag) {
      return document.findAllElements(tag).firstOrNull?.innerText.trim() ?? '';
    }

    int readInt(String tag) {
      return int.tryParse(readText(tag)) ?? 0;
    }

    return RouterLinkContext(
      systemMode: readInt('sys_mode'),
      dataMode: readInt('data_mode'),
      rssi: readInt('rssi'),
      registrationStatus: readInt('RegStatus'),
      networkName: readText('network_name'),
      roamingStatus: readInt('roaming_status'),
      connectionStatus: readInt('connection_status'),
      ipv4Address: readText('ipv4_ip'),
      roaming: readInt('roaming'),
      roamingNetworkName: readText('roaming_network_name'),
    );
  }
}
