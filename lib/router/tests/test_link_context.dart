import '../router_client.dart';
import '../parsers/router_link_context_parser.dart';

Future<void> main() async {
  final router = RouterClient();

  try {
    final loggedIn = await router.login(
      username: 'admin',
      password: const String.fromEnvironment('ROUTER_PASSWORD'),
    );

    if (!loggedIn) {
      print('Login failed.');
      return;
    }

    final response = await router.postXml('cm', 'get_link_context');

    final context = RouterLinkContextParser.parse(response.data ?? '');

    print('Network: ${context.networkName}');
    print('Mode: ${context.networkMode}');
    print('Signal: ${context.signalDbm ?? 'N/A'} dBm');
    print('Signal bars: ${context.signalBars}/3');
    print('Registered: ${context.isRegistered}');
    print('Connected: ${context.isConnected}');
    print('Roaming: ${context.isRoaming}');
    print('Mobile IP: ${context.ipv4Address}');
  } catch (e) {
    print('Link-context request failed: $e');
  } finally {
    router.close();
  }
}
