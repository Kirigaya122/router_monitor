import 'package:xml/xml.dart';

class RouterXml {
  static String buildRequest(
    String objPath,
    String objMethod, {
    Map<String, String>? params,
  }) {
    final paramChildren = <XmlNode>[
      XmlElement(XmlName.parts('method'), [], [XmlText('call')]),
      XmlElement(XmlName.parts('session'), [], [XmlText('000')]),
      XmlElement(XmlName.parts('obj_path'), [], [XmlText(objPath)]),
      XmlElement(XmlName.parts('obj_method'), [], [XmlText(objMethod)]),
    ];

    if (params != null) {
      for (final entry in params.entries) {
        paramChildren.add(
          XmlElement(XmlName.parts(entry.key), [], [XmlText(entry.value)]),
        );
      }
    }

    final document = XmlDocument([
      XmlProcessing('xml', 'version="1.0" encoding="US-ASCII"'),
      XmlElement(XmlName.parts('RGW'), [], [
        XmlElement(XmlName.parts('param'), [], paramChildren),
      ]),
    ]);

    return document.toXmlString(pretty: false);
  }
}
