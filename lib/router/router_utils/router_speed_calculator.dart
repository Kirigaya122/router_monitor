class RouterSpeedCalculator {
  int? _previousRxBytes;
  int? _previousTxBytes;

  DateTime? _previousTime;

  void reset() {
    _previousRxBytes = null;
    _previousTxBytes = null;
    _previousTime = null;
  }

  RouterSpeeds update({
    required int totalRxBytes,
    required int totalTxBytes,
    required DateTime timestamp,
  }) {
    final previousRx = _previousRxBytes;
    final previousTx = _previousTxBytes;
    final previousTime = _previousTime;

    // Save this reading for the next calculation.
    _previousRxBytes = totalRxBytes;
    _previousTxBytes = totalTxBytes;
    _previousTime = timestamp;

    // The first reading establishes a baseline.
    if (previousRx == null || previousTx == null || previousTime == null) {
      return const RouterSpeeds(
        downloadBytesPerSecond: 0,
        uploadBytesPerSecond: 0,
      );
    }

    final elapsedSeconds =
        timestamp.difference(previousTime).inMicroseconds /
        Duration.microsecondsPerSecond;

    if (elapsedSeconds <= 0) {
      return const RouterSpeeds(
        downloadBytesPerSecond: 0,
        uploadBytesPerSecond: 0,
      );
    }

    // Avoid negative speeds if counters reset or roll over.
    final receivedBytes = totalRxBytes >= previousRx
        ? totalRxBytes - previousRx
        : 0;

    final sentBytes = totalTxBytes >= previousTx
        ? totalTxBytes - previousTx
        : 0;

    return RouterSpeeds(
      downloadBytesPerSecond: receivedBytes / elapsedSeconds,
      uploadBytesPerSecond: sentBytes / elapsedSeconds,
    );
  }
}

class RouterSpeeds {
  final double downloadBytesPerSecond;
  final double uploadBytesPerSecond;

  const RouterSpeeds({
    required this.downloadBytesPerSecond,
    required this.uploadBytesPerSecond,
  });
}
