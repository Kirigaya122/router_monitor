import '../router/router_client.dart';
import '../router/router_models.dart';
import '../router/router_link_context.dart';
import '../router/parsers/router_statistics_parser.dart';
import '../router/parsers/router_battery_parser.dart';
import '../router/parsers/router_clients_parser.dart';
import '../router/parsers/router_link_context_parser.dart';
import '../router/parsers/router_clients_devices_parser.dart';
import '../router/router_utils/router_speed_calculator.dart';

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
  final RouterClient _client = RouterClient();
  final RouterSpeedCalculator _speedCalculator = RouterSpeedCalculator();

  bool _loggedIn = false;
  bool _disposed = false;
  Future<void>? _connectionAttempt;

  /// Authenticate using credentials entered at runtime.
  Future<void> connect({
    required String username,
    required String password,
  }) async {
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    if (_loggedIn) return;

    // Avoid simultaneous login attempts using the same client.
    final existingAttempt = _connectionAttempt;
    if (existingAttempt != null) {
      await existingAttempt;
      return;
    }

    final attempt = _performLogin(username: username, password: password);

    _connectionAttempt = attempt;

    try {
      await attempt;
    } finally {
      if (identical(_connectionAttempt, attempt)) {
        _connectionAttempt = null;
      }
    }
  }

  Future<void> _performLogin({
    required String username,
    required String password,
  }) async {
    final success = await _client.login(username: username, password: password);

    if (!success) {
      throw StateError('Router login was not successful.');
    }

    _loggedIn = true;
  }

  Future<void> _ensureLoggedIn() async {
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    if (!_loggedIn) {
      throw StateError('Not connected to the router. Please log in first.');
    }
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
    await _ensureLoggedIn();

    // Keep these sequential: this order works with your router.
    final statisticsXml = await _request('statistics', 'stat_get_common_data');

    final batteryXml = await _request('aoc', 'get_chg_info');

    final clientsXml = await _request('statistics', 'get_active_clients_num');

    final linkContextXml = await _request('cm', 'get_link_context');

    final statistics = RouterStatisticsParser.parse(statisticsXml);

    final battery = RouterBatteryParser.parse(batteryXml);

    final clients = RouterClients.fromXml(clientsXml);

    final linkContext = RouterLinkContextParser.parse(linkContextXml);

    final now = DateTime.now();

    final speeds = _speedCalculator.update(
      totalRxBytes: statistics.totalRxBytes,
      totalTxBytes: statistics.totalTxBytes,
      timestamp: now,
    );

    return RouterDashboardData(
      statistics: statistics,
      battery: battery,
      clients: clients,
      linkContext: linkContext,
      speeds: speeds,
      updatedAt: now,
    );
  }

  Future<List<RouterClientDevice>> fetchConnectedDevices() async {
    await _ensureLoggedIn();

    final xml = await _request('statistics', 'get_conn_clients_info');

    return RouterClientDevicesParser.parse(xml);
  }

  Future<void> logout() async {
    if (_disposed) return;

    try {
      await _client.logout();
    } finally {
      _loggedIn = false;
      dispose();
    }
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _client.close();
  }
}
