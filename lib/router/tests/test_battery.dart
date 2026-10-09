import '../router_utils/router_formatters.dart';

void main() {
  print(RouterFormatters.formatTrafficBytes(1024));
  print(RouterFormatters.formatTrafficBytes(1048576));
  print(RouterFormatters.formatTrafficBytes(1073741824));
  print(RouterFormatters.formatTrafficBytes(5923519911));
}
// import '../router_client.dart';
// import '../parsers/router_battery_parser.dart';

// Future<void> main() async {
//   final router = RouterClient();

//   try {
//     final loggedIn = await router.login(
//       username: 'admin',
//       password: const String.fromEnvironment('ROUTER_PASSWORD'),
//     );

//     print('Login confirmed: $loggedIn');

//     final response = await router.postXml('aoc', 'get_chg_info');

//     final battery = RouterBatteryParser.parse(response.data ?? '');

//     print('Battery: ${battery.capacity}%');
//     print('Status: ${battery.statusLabel}');
//     print('Voltage: ${battery.voltageVolts} V');
//     print('Temperature: ${battery.temperatureCelsius} °C');
//     print('AC charging: ${battery.isAcChargingOnline}');
//     print('USB charging: ${battery.isUsbChargingOnline}');

//     print('HTTP status: ${response.statusCode}');
//   } catch (e) {
//     print('Battery request failed: $e');
//   } finally {
//     router.close();
//   }
// }
