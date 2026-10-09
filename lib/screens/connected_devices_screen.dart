import 'package:flutter/material.dart';

import '../router/router_models.dart';
import '../services/router_service.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  final RouterService service;

  const ConnectedDevicesScreen({super.key, required this.service});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  List<RouterClientDevice> _devices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    if (_loading && _devices.isNotEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devices = await widget.service.fetchConnectedDevices();

      if (!mounted) return;

      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Bad state: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected devices'),
        actions: [
          IconButton(
            tooltip: 'Refresh devices',
            onPressed: _loading ? null : _loadDevices,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDevices,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${_devices.length} ${_devices.length == 1 ? 'device' : 'devices'}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Devices currently reported by your router',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            if (_loading && _devices.isEmpty) ...[
              const SizedBox(height: 60),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              const Center(child: Text('Loading connected devices…')),
            ] else if (_error != null && _devices.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 42),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadDevices,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_devices.isEmpty) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.devices_other_rounded, size: 44),
                      SizedBox(height: 12),
                      Text('No connected devices reported.'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Refresh failed: $_error',
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ..._devices.map(
                (device) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DeviceCard(device: device),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final RouterClientDevice device;

  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final deviceName = device.name.trim().isEmpty || device.name.trim() == '*'
        ? 'Unknown device'
        : device.name.trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  child: Icon(
                    device.connectionType.toUpperCase().contains('WIFI')
                        ? Icons.wifi_rounded
                        : Icons.devices_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(device.connectionType),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _DetailRow(label: 'IP address', value: _display(device.ipAddress)),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'MAC address',
              value: _display(device.macAddress),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Connected for',
              value: device.connectionDuration,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'DHCP lease remaining',
              value: device.leaseRemaining,
            ),
          ],
        ),
      ),
    );
  }

  String _display(String value) {
    return value.trim().isEmpty ? 'Not reported' : value;
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: SelectableText(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
