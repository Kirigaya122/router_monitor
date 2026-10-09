import 'package:xml/xml.dart';

import '../router_models.dart';

class RouterClientDevicesParser {
  static List<RouterClientDevice> parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    return document.findAllElements('one_client').map((element) {
      String readText(String tag) {
        return element.getElement(tag)?.innerText.trim() ?? '';
      }

      int readInt(String tag) {
        return int.tryParse(readText(tag)) ?? 0;
      }

      return RouterClientDevice(
        macAddress: readText('mac'),
        connectionType: readText('type'),
        ipAddress: readText('ip'),
        name: readText('name'),
        connectionTimeSeconds: readInt('cur_conn_time'),
        leaseRemainingSeconds: readInt('lease_remain_time'),
      );
    }).toList();
  }
}
