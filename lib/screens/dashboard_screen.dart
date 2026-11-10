import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'dart:async';

import '../router/router_utils/router_formatters.dart';
import '../services/router_service.dart';
import 'connected_devices_screen.dart';
import 'router_login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final RouterService service;

  const DashboardScreen({super.key, required this.service});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RouterService _routerService = widget.service;

  RouterDashboardData? _data;
  String? _error;
  bool _loading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_loading) {
        _refresh(silent: true);
      }
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_loading && _data != null) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _routerService.refresh();

      if (!mounted) return;

      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        if (!silent || _data == null) {
          _error = _friendlyError(error);
        }

        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'This will end your router session in the app '
          'and return you to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Stop background polling before logging out.
    _pollingTimer?.cancel();

    try {
      await _routerService.logout();
    } catch (_) {
      // Return to login even if the router is unreachable.
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const RouterLoginScreen()),
      (route) => false,
    );
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The router took too long to respond. Try again.';

        case DioExceptionType.connectionError:
          return 'Could not reach the router. Connect to its Wi-Fi '
              'and check that 192.168.1.1 is reachable.';

        default:
          break;
      }
    }

    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('timed out')) {
      return 'Could not reach the router. Connect to its Wi-Fi and '
          'check that 192.168.1.1 is reachable.';
    }

    if (message.contains('Digest challenge') ||
        message.contains('Login not confirmed') ||
        message.contains('Authenticate first')) {
      return 'Router login failed. Check the username and password.';
    }

    return message.replaceFirst('Bad state: ', '');
  }

  void _openConnectedDevices() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConnectedDevicesScreen(service: _routerService),
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _routerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final data = _data;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.router_rounded),
            SizedBox(width: 12),
            Text('Router Monitor'),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Refresh router data',
            child: IconButton(
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Log out',
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Your network at a glance',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Local status for your TNM router',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_loading && data == null) ...[
                    const SizedBox(height: 70),
                    const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 16),
                    const Center(child: Text('Connecting to your router…')),
                  ] else if (_error != null && data == null) ...[
                    _ErrorPanel(message: _error!, onRetry: _refresh),
                  ] else if (data != null) ...[
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _InlineWarning(message: _error!),
                      ),

                    if (_loading) const LinearProgressIndicator(),

                    _ConnectionCard(data: data),
                    const SizedBox(height: 16),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850
                            ? 3
                            : constraints.maxWidth >= 560
                            ? 2
                            : 1;

                        const gap = 16.0;
                        final cardWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _SpeedCard(data: data),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _TrafficCard(data: data),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _BatteryCard(data: data),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _ClientsCard(
                                data: data,
                                onTap: _openConnectedDevices,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Last updated: ${_formatTime(data.updatedAt)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _ConnectionCard extends StatelessWidget {
  final RouterDashboardData data;

  const _ConnectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final link = data.linkContext;
    final connected = link.isConnected;

    final operator = link.networkOperator.isEmpty
        ? 'Mobile network'
        : link.networkOperator;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cell_tower_rounded,
                  size: 34,
                  color: colors.onPrimaryContainer,
                ),
                const Spacer(),
                _StatusPill(
                  label: link.connectionStatusLabel,
                  active: connected,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              operator,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${link.networkMode} mobile network',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt_rounded,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Signal',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ),
                Text(
                  '${'▮' * link.signalBars}${'▯' * (3 - link.signalBars)}'
                  '  ${link.signalDbm == null ? 'N/A' : '${link.signalDbm} dBm'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (link.isRoaming) ...[
              const SizedBox(height: 8),
              Text(
                'Roaming',
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final RouterDashboardData data;

  const _SpeedCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Live speed',
      icon: Icons.speed_rounded,
      child: Column(
        children: [
          _SpeedRow(
            label: 'Download',
            icon: Icons.south_rounded,
            value: _formatSpeed(data.speeds.downloadBytesPerSecond),
          ),
          const SizedBox(height: 18),
          _SpeedRow(
            label: 'Upload',
            icon: Icons.north_rounded,
            value: _formatSpeed(data.speeds.uploadBytesPerSecond),
          ),
          const SizedBox(height: 12),
          Text(
            'Speed is calculated from successive readings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }

    if (bytesPerSecond >= 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }

    return '${bytesPerSecond.toStringAsFixed(0)} B/s';
  }
}

class _SpeedRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;

  const _SpeedRow({
    required this.label,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TrafficCard extends StatelessWidget {
  final RouterDashboardData data;

  const _TrafficCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = data.statistics;

    return _DashboardCard(
      title: 'Traffic statistics',
      icon: Icons.data_usage_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Since power-on',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Received')),
              Text(RouterFormatters.formatTrafficBytes(stats.rxBytes)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('Uploaded')),
              Text(RouterFormatters.formatTrafficBytes(stats.txBytes)),
            ],
          ),
          const Divider(height: 30),
          Text(
            'Since factory reset',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(child: Text('Downloaded')),
              Text(RouterFormatters.formatTrafficBytes(stats.totalRxBytes)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('Uploaded')),
              Text(RouterFormatters.formatTrafficBytes(stats.totalTxBytes)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(child: Text('Total')),
              Text(RouterFormatters.formatTrafficBytes(stats.totalRxTxBytes)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final RouterDashboardData data;

  const _BatteryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final battery = data.battery;
    final colors = Theme.of(context).colorScheme;
    final level = battery.capacity.clamp(0, 100) / 100.0;

    return _DashboardCard(
      title: 'Battery',
      icon: Icons.battery_charging_full_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                battery.isPresent ? '${battery.capacity}%' : 'N/A',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Icon(
                battery.status == 1
                    ? Icons.battery_charging_full_rounded
                    : Icons.battery_std_rounded,
                size: 34,
                color: colors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: battery.isPresent ? level : 0,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            battery.statusLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            battery.isAcChargingOnline || battery.isUsbChargingOnline
                ? 'External power detected'
                : 'No external power reported',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ClientsCard extends StatelessWidget {
  final RouterDashboardData data;
  final VoidCallback onTap;

  const _ClientsCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final clients = data.clients;

    return _DashboardCard(
      title: 'Connected devices',
      icon: Icons.devices_rounded,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right_rounded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${clients.activeClients}',
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Text('Currently connected'),
          const Divider(height: 28),
          _ClientRow(
            label: 'Wi-Fi 2.4 GHz',
            count: clients.active24gWifiClients,
          ),
          const SizedBox(height: 12),
          _ClientRow(label: 'LAN', count: clients.activeLanClients),
          const SizedBox(height: 12),
          _ClientRow(label: 'USB', count: clients.activeUsbClients),
          const SizedBox(height: 16),
          Text(
            'Tap to view connected devices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final String label;
  final int count;

  const _ClientRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    IconTheme(
                      data: IconThemeData(color: colors.onSurfaceVariant),
                      child: trailing!,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = active
        ? const Color(0xFF16834A)
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active
            ? const Color(0x1F16834A)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Unable to load router data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Refresh failed: $message',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
