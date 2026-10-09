import '../router_utils/router_speed_calculator.dart';

void main() {
  final calculator = RouterSpeedCalculator();

  final firstTime = DateTime(2026, 10, 9, 12, 0, 0);
  final secondTime = firstTime.add(const Duration(seconds: 2));

  // First reading: establish the baseline.
  final first = calculator.update(
    totalRxBytes: 1000000,
    totalTxBytes: 200000,
    timestamp: firstTime,
  );

  print('First download: ${first.downloadBytesPerSecond} B/s');
  print('First upload: ${first.uploadBytesPerSecond} B/s');

  // Two seconds later, 400 KB received and 100 KB sent.
  final second = calculator.update(
    totalRxBytes: 1400000,
    totalTxBytes: 300000,
    timestamp: secondTime,
  );

  print('Download: ${second.downloadBytesPerSecond} B/s');
  print('Upload: ${second.uploadBytesPerSecond} B/s');
}
