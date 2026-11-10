import 'package:flutter/material.dart';

import '../services/router_service.dart';
import 'dashboard_screen.dart';
import 'router_login_screen.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final service = RouterService();
    final ok = await service.tryAutoLogin();

    if (!mounted) {
      service.dispose();
      return;
    }

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(service: service),
        ),
      );
    } else {
      service.dispose();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RouterLoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.router_rounded, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'Router Monitor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
