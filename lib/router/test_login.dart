import 'router_client.dart';

Future<void> main() async {
  final router = RouterClient();

  try {
    final loggedIn = await router.login(
      username: 'admin',
      password: const String.fromEnvironment('ROUTER_PASSWORD'),
    );

    print('Login confirmed: $loggedIn');
  } catch (e) {
    print('Login failed: $e');
  } finally {
    router.close();
  }
}
