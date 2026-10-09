import 'package:xml/xml.dart';

import 'router_models.dart';

class RouterStatisticsParser {
  static RouterStatistics parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);

    // Find the <statistics> element.
    final statistics = document.findAllElements('statistics').firstOrNull;

    if (statistics == null) {
      throw const FormatException(
        'The response does not contain a statistics element.',
      );
    }

    String readText(String tag) {
      final element = statistics.getElement(tag);

      if (element == null) {
        throw FormatException('Missing "$tag" in statistics response.');
      }

      return element.innerText.trim();
    }

    int readInt(String tag) {
      final value = int.tryParse(readText(tag));

      if (value == null) {
        throw FormatException('Invalid integer for "$tag".');
      }

      return value;
    }

    double readDouble(String tag) {
      final value = double.tryParse(readText(tag));

      if (value == null) {
        throw FormatException('Invalid number for "$tag".');
      }

      return value;
    }

    return RouterStatistics(
      rxBytes: readInt('rx_bytes'),
      txBytes: readInt('tx_bytes'),
      rxTxBytes: readInt('rx_tx_bytes'),
      monthRxBytes: readInt('month_rx_bytes'),
      monthTxBytes: readInt('month_tx_bytes'),
      totalRxPackets: readInt('total_rx_packets'),
      totalTxPackets: readInt('total_tx_packets'),
      totalRxTxPackets: readInt('total_rx_tx_packets'),
      upThroughput: readDouble('upthrpt'),
      downThroughput: readDouble('dnthrpt'),
    );
  }
}
