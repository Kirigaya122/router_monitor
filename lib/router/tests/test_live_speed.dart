import 'dart:async';

import '../router_client.dart';
import '../parsers/router_statistics_parser.dart';
import '../router_utils/router_speed_calculator.dart';

Future<void> main() async {
  final router = RouterClient();
  final calculator = RouterSpeedCalculator();

  try {
    final loggedIn = await router.login(
      username: 'admin',
      password: const String.fromEnvironment('ROUTER_PASSWORD'),
    );

    if (!loggedIn) {
      print('Login failed.');
      return;
    }

    print('Connected! Measuring live traffic...');
    print('Press Ctrl+C to stop.\n');

    while (true) {
      try {
        final response = await router.postXml(
          'statistics',
          'stat_get_common_data',
        );

        final body = response.data;

        if (body == null || body.isEmpty) {
          print('Empty statistics response.');
        } else {
          final statistics = RouterStatisticsParser.parse(body);

          final speeds = calculator.update(
            totalRxBytes: statistics.totalRxBytes,
            totalTxBytes: statistics.totalTxBytes,
            timestamp: DateTime.now(),
          );

          final download = speeds.downloadBytesPerSecond / 1024;
          final upload = speeds.uploadBytesPerSecond / 1024;

          print(
            '↓ ${download.toStringAsFixed(2)} KB/s'
            '   ↑ ${upload.toStringAsFixed(2)} KB/s'
            '   | Received: ${statistics.totalRxBytes}'
            '   | Sent: ${statistics.totalTxBytes}',
          );
        }
      } catch (e) {
        print('Statistics request failed: $e');
      }

      await Future<void>.delayed(const Duration(seconds: 2));
    }
  } catch (e) {
    print('Router connection failed: $e');
  } finally {
    router.close();
  }
}
