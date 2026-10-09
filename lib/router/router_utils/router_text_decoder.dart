class RouterTextDecoder {
  static String decode(String encoded) {
    if (encoded.isEmpty || encoded.length % 4 != 0) {
      return '';
    }

    final result = StringBuffer();

    for (var i = 0; i < encoded.length; i += 4) {
      final codeUnit = int.tryParse(encoded.substring(i, i + 4), radix: 16);

      if (codeUnit == null) {
        return '';
      }

      result.writeCharCode(codeUnit);
    }

    return result.toString();
  }
}
