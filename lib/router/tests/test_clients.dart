import '../router_client.dart';

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

    final response = await router.postXml(
      'statistics',
      'get_active_clients_num',
    );

    print('HTTP status: ${response.statusCode}');
    print('Response body: ${response.data}');
  } catch (e) {
    print('Client-count request failed: $e');
  } finally {
    router.close();
  }
}
