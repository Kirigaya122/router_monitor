import '../router/router_client.dart';
import '../router/router_models.dart';
import '../router/router_link_context.dart';
import '../router/parsers/router_statistics_parser.dart';
import '../router/parsers/router_battery_parser.dart';
import '../router/parsers/router_clients_parser.dart';
import '../router/parsers/router_link_context_parser.dart';
import '../router/router_utils/router_speed_calculator.dart';
import '../router/parsers/router_clients_devices_parser.dart';

class RouterDashboardData {
  final RouterStatistics statistics;
  final RouterBattery battery;
  final RouterClients clients;
  final RouterLinkContext linkContext;
  final RouterSpeeds speeds;
  final DateTime updatedAt;

  const RouterDashboardData({
    required this.statistics,
    required this.battery,
    required this.clients,
    required this.linkContext,
    required this.speeds,
    required this.updatedAt,
  });
}

class RouterService {
  static const _username = String.fromEnvironment(
    'ROUTER_USERNAME',
    defaultValue: 'admin',
  );

  static const _password = String.fromEnvironment('ROUTER_PASSWORD');

  final RouterClient _client = RouterClient();
  final RouterSpeedCalculator _speedCalculator = RouterSpeedCalculator();

  bool _loggedIn = false;
  bool _disposed = false;

  Future<void> _ensureLoggedIn() async {
    if (_loggedIn) return;

    if (_password.isEmpty) {
      throw StateError(
        'Missing ROUTER_PASSWORD. Start the app with the required '
        'compile-time configuration.',
      );
    }

    final success = await _client.login(
      username: _username,
      password: _password,
    );

    if (!success) {
      throw StateError('Router login was not successful.');
    }

    _loggedIn = true;
  }

  Future<String> _request(String path, String method) async {
    final response = await _client.postXml(path, method);

    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw StateError(
        'Router request failed with HTTP ${response.statusCode}.',
      );
    }

    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const FormatException('The router returned an empty response.');
    }

    return body;
  }

  Future<RouterDashboardData> refresh() async {
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    await _ensureLoggedIn();

    // Fetch independently so these requests can run together.
    final responses = await Future.wait([
      _request('statistics', 'stat_get_common_data'),
      _request('aoc', 'get_chg_info'),
      _request('statistics', 'get_active_clients_num'),
      _request('cm', 'get_link_context'),
    ]);

    final statistics = RouterStatisticsParser.parse(responses[0]);
    final battery = RouterBatteryParser.parse(responses[1]);
    final clients = RouterClients.fromXml(responses[2]);
    final linkContext = RouterLinkContextParser.parse(responses[3]);

    final speeds = _speedCalculator.update(
      totalRxBytes: statistics.totalRxBytes,
      totalTxBytes: statistics.totalTxBytes,
      timestamp: DateTime.now(),
    );

    return RouterDashboardData(
      statistics: statistics,
      battery: battery,
      clients: clients,
      linkContext: linkContext,
      speeds: speeds,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<RouterClientDevice>> fetchConnectedDevices() async {
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    await _ensureLoggedIn();

    final xml = await _request('statistics', 'get_conn_clients_info');

    return RouterClientDevicesParser.parse(xml);
  }

  void dispose() {
    _disposed = true;
    _client.close();
  }
}
