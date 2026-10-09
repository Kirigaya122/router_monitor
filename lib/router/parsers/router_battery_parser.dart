import 'package:xml/xml.dart';

import '../router_models.dart';

class RouterBatteryParser {
  static RouterBattery parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final root = document.rootElement;

    String readText(String tag) {
      final element = root.getElement(tag);

      if (element == null) {
        throw FormatException('Battery response is missing "$tag".');
      }

      return element.innerText.trim();
    }

    int readInt(String tag) {
      final value = int.tryParse(readText(tag));

      if (value == null) {
        throw FormatException('Battery field "$tag" is not a valid integer.');
      }

      return value;
    }

    return RouterBattery(
      capacity: readInt('capacity'),
      health: readInt('health'),
      present: readInt('present'),
      type: readInt('type'),
      voltageNow: readInt('voltage_now'),
      status: readInt('bat_status'),
      temperature: readInt('bat_temp'),
      technology: readInt('bat_technology'),
      acChargingOnline: readInt('acchg_online'),
      acChargingType: readInt('acchg_type'),
      acChargingStatus: readInt('acchg_status'),
      usbChargingOnline: readInt('usbchg_online'),
      usbChargingType: readInt('usbchg_type'),
      usbChargingStatus: readInt('usbchg_status'),
    );
  }
}
