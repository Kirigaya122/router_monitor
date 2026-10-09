import 'router_client.dart';
import 'router_statistics_parser.dart';

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

    print('Received: ${statistics.rxBytes} bytes');
    print('Sent: ${statistics.txBytes} bytes');
    print('Monthly received: ${statistics.monthRxBytes} bytes');
    print('Monthly sent: ${statistics.monthTxBytes} bytes');
    print('Upload throughput: ${statistics.upThroughput}');
    print('Download throughput: ${statistics.downThroughput}');
  } catch (e) {
    print('Statistics test failed: $e');
  } finally {
    router.close();
  }
}
