import '../parsers/router_clients_devices_parser.dart';
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
      'get_conn_clients_info',
    );

    final devices = RouterClientDevicesParser.parse(response.data ?? '');

    print('Connected devices: ${devices.length}');
    print('');

    for (final device in devices) {
      print('Name: ${device.name}');
      print('IP: ${device.ipAddress}');
      print('MAC: ${device.macAddress}');
      print('Type: ${device.connectionType}');
      print('Connected for: ${device.connectionDuration}');
      print('DHCP lease remaining: ${device.leaseRemaining}');
      print('------------------------------');
    }
  } catch (e) {
    print('Device-list request failed: $e');
  } finally {
    router.close();
  }
}
