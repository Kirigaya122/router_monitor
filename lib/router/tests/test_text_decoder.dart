import '../router_utils/router_text_decoder.dart';

void main() {
  const encoded = '0054004e004d';

  final decoded = RouterTextDecoder.decode(encoded);

  print('Encoded: $encoded');
  print('Decoded: $decoded');

  assert(decoded == 'TNM');
  assert(RouterTextDecoder.decode('') == '');
  assert(RouterTextDecoder.decode('123') == '');

  print('All tests passed.');
}
