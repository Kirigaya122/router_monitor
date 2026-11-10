import 'package:dio/dio.dart';

import '../router/router_client.dart';
import '../router/router_models.dart';
import '../router/router_link_context.dart';
import '../router/parsers/router_statistics_parser.dart';
import '../router/parsers/router_battery_parser.dart';
import '../router/parsers/router_clients_parser.dart';
import '../router/parsers/router_link_context_parser.dart';
import '../router/parsers/router_clients_devices_parser.dart';
import '../router/router_utils/router_speed_calculator.dart';
import 'credential_store.dart';

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
  final CredentialStore _credentialStore = CredentialStore();

  bool _loggedIn = false;
  bool _disposed = false;
  Future<void>? _loginFuture;

  Future<void> connect({
    required String username,
    required String password,
  }) async {
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    if (_loggedIn) return;

    // Prevent concurrent login attempts from racing each other.
    final existing = _loginFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _doLogin(username: username, password: password);
    _loginFuture = future;

    try {
      await future;
    } finally {
      _loginFuture = null;
    }
  }

  Future<void> _doLogin({
    required String username,
    required String password,
  }) async {
    final success = await _client.login(username: username, password: password);

    if (!success) {
      throw StateError('Router login was not successful.');
    }

    _loggedIn = true;

    // Best-effort persistence. If saving fails (e.g. keychain
    // unavailable), the app still works; the user just won't get
    // auto-login on the next launch.
    try {
      await _credentialStore.save(username: username, password: password);
    } catch (_) {}
  }

  /// Attempts to log in using saved credentials.
  ///
  /// Returns true if login succeeded. If credentials are missing or
  /// invalid, they are cleared. If the router is simply unreachable,
  /// the credentials are kept so auto-login can be retried next launch.
  Future<bool> tryAutoLogin() async {
    ({String username, String password})? saved;

    try {
      saved = await _credentialStore.read();
    } catch (_) {
      return false;
    }

    if (saved == null) return false;

    try {
      await connect(username: saved.username, password: saved.password);
      return true;
    } on DioException catch (e) {
      final isNetworkError =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout;

      if (!isNetworkError) {
        await _credentialStore.clear();
      }

      return false;
    } catch (_) {
      await _credentialStore.clear();
      return false;
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
    if (_disposed) {
      throw StateError('Router service has been disposed.');
    }

    await _ensureLoggedIn();

    final statisticsXml = await _request('statistics', 'stat_get_common_data');
    final batteryXml = await _request('aoc', 'get_chg_info');
    final clientsXml = await _request('statistics', 'get_active_clients_num');
    final linkContextXml = await _request('cm', 'get_link_context');

    final statistics = RouterStatisticsParser.parse(statisticsXml);
    final battery = RouterBatteryParser.parse(batteryXml);
    final clients = RouterClients.fromXml(clientsXml);
    final linkContext = RouterLinkContextParser.parse(linkContextXml);

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

  Future<void> _ensureLoggedIn() async {
    if (_loggedIn) return;
    throw StateError(
      'Router service is not connected. Call connect() or tryAutoLogin() first.',
    );
  }

  Future<void> logout() async {
    try {
      await _client.logout();
    } catch (_) {}

    await _credentialStore.clear();

    _loggedIn = false;
    dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _client.close();
  }
}
