class RouterFormatters {
  static String formatTrafficBytes(num dataBytes) {
    if (dataBytes > 1024 * 1024 * 1024) {
      final dataInGB = dataBytes / (1024 * 1024 * 1024);
      return '${dataInGB.toStringAsFixed(2)}GB';
    } else if (dataBytes > 1024 * 1024) {
      final dataInMB = dataBytes / (1024 * 1024);
      return '${dataInMB.toStringAsFixed(2)}MB';
    } else {
      final dataInKB = dataBytes / 1024;
      return '${dataInKB.toStringAsFixed(2)}KB';
    }
  }
}
