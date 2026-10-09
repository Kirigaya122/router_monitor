import 'package:xml/xml.dart';

import '../router_models.dart';

class RouterStatisticsParser {
  static RouterStatistics parse(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final elements = document.findAllElements('statistics');

    if (elements.isEmpty) {
      throw const FormatException(
        'The response does not contain a statistics element.',
      );
    }

    final statistics = elements.first;

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
      // Current traffic counters
      rxBytes: readInt('rx_bytes'),
      txBytes: readInt('tx_bytes'),
      rxTxBytes: readInt('rx_tx_bytes'),
      errorBytes: readInt('error_bytes'),

      // Monthly traffic counters
      monthRxBytes: readInt('month_rx_bytes'),
      monthTxBytes: readInt('month_tx_bytes'),

      // Total traffic counters
      totalRxBytes: readInt('total_rx_bytes'),
      totalTxBytes: readInt('total_tx_bytes'),
      totalRxTxBytes: readInt('total_rx_tx_bytes'),
      totalErrorBytes: readInt('total_error_bytes'),

      // Packet counters
      totalRxPackets: readInt('total_rx_packets'),
      totalTxPackets: readInt('total_tx_packets'),
      totalRxTxPackets: readInt('total_rx_tx_packets'),

      // Current throughput
      upThroughput: readDouble('upthrpt'),
      downThroughput: readDouble('dnthrpt'),

      // Average throughput
      averageUpThroughput: readDouble('avg_upthrpt'),
      averageDownThroughput: readDouble('avg_dnthrpt'),

      // Maximum throughput
      maximumUpThroughput: readDouble('max_upthrpt'),
      maximumDownThroughput: readDouble('max_dnthrpt'),
    );
  }
}
