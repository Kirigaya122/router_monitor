class RouterStatistics {
  final int rxBytes;
  final int txBytes;
  final int rxTxBytes;

  final int monthRxBytes;
  final int monthTxBytes;

  final int totalRxPackets;
  final int totalTxPackets;
  final int totalRxTxPackets;

  final double upThroughput;
  final double downThroughput;

  const RouterStatistics({
    required this.rxBytes,
    required this.txBytes,
    required this.rxTxBytes,
    required this.monthRxBytes,
    required this.monthTxBytes,
    required this.totalRxPackets,
    required this.totalTxPackets,
    required this.totalRxTxPackets,
    required this.upThroughput,
    required this.downThroughput,
  });
}
