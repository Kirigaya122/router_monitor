import '../router_client.dart';
import '../parsers/router_statistics_parser.dart';

Future<void> main() async {
  final router = RouterClient();

  try {
    await router.login(
      username: 'admin',
      password: const String.fromEnvironment('ROUTER_PASSWORD'),
    );

    final response = await router.postXml('statistics', 'stat_get_common_data');

    final body = response.data;

    if (body == null || body.isEmpty) {
      throw StateError('The router returned an empty response.');
    }

    final statistics = RouterStatisticsParser.parse(body);

    print('Current errors: ${statistics.errorBytes}');
    print('Total received: ${statistics.totalRxBytes}');
    print('Total sent: ${statistics.totalTxBytes}');
    print('Total combined: ${statistics.totalRxTxBytes}');
    print('Total errors: ${statistics.totalErrorBytes}');

    print('Received packets: ${statistics.totalRxPackets}');
    print('Sent packets: ${statistics.totalTxPackets}');
    print('Combined packets: ${statistics.totalRxTxPackets}');

    print(
      'Average upload throughput: '
      '${statistics.averageUpThroughput}',
    );
    print(
      'Average download throughput: '
      '${statistics.averageDownThroughput}',
    );

    print(
      'Maximum upload throughput: '
      '${statistics.maximumUpThroughput}',
    );
    print(
      'Maximum download throughput: '
      '${statistics.maximumDownThroughput}',
    );

    // print('Received: ${statistics.rxBytes} bytes');
    // print('Sent: ${statistics.txBytes} bytes');
    // print('Monthly received: ${statistics.monthRxBytes} bytes');
    // print('Monthly sent: ${statistics.monthTxBytes} bytes');
    // print('Upload throughput: ${statistics.upThroughput}');
    // print('Download throughput: ${statistics.downThroughput}');
  } catch (e) {
    print('Statistics test failed: $e');
  } finally {
    router.close();
  }
}
