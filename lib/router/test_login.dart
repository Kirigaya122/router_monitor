import 'router_client.dart';
import 'router_xml.dart';

Future<void> main() async {
  final router = RouterClient();

  try {
    final loggedIn = await router.login(
      username: 'admin',
      password: const String.fromEnvironment('ROUTER_PASSWORD'),
    );

    final runtimeData = await router.postXml(
      'statistics',
      'stat_get_common_data',
    );

    print('HTTP status: ${runtimeData.statusCode}');
    print('Response headers: ${runtimeData.headers}');
    print('Response data: ${runtimeData.data}');
    print('Response type: ${runtimeData.data.runtimeType}');
    print('Request XML: ${RouterXml.buildRequest('account', 'get_account')}');
  } catch (e) {
    print('Login failed: $e');
  } finally {
    router.close();
  }
}
