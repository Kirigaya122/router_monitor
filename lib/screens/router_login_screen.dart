import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/router_service.dart';
import 'dashboard_screen.dart';

class RouterLoginScreen extends StatefulWidget {
  const RouterLoginScreen({super.key});

  @override
  State<RouterLoginScreen> createState() => _RouterLoginScreenState();
}

class _RouterLoginScreenState extends State<RouterLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _connecting = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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

    if (message.contains('Digest challenge') ||
        message.contains('Login not confirmed') ||
        message.contains('Router login was not successful')) {
      return 'Login failed. Check your username and password.';
    }

    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('timed out')) {
      return 'Could not reach 192.168.1.1. Make sure you are '
          'connected to your router.';
    }

    return message.replaceFirst('Bad state: ', '');
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate() || _connecting) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _connecting = true;
      _error = null;
    });

    final service = RouterService();

    try {
      await service.connect(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        service.dispose();
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DashboardScreen(service: service),
        ),
      );
    } catch (error) {
      service.dispose();

      if (!mounted) return;

      setState(() {
        _error = _friendlyError(error);
        _connecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        size: 42,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Router Monitor',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your TNM router.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usernameController,
                      enabled: !_connecting,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your router username.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_connecting,
                      obscureText: _obscurePassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _connect(),
                      decoration: InputDecoration(
                        labelText: 'Router password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: _connecting
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your router password.';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: colors.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _connecting ? null : _connect,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _connecting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Connecting…'),
                              ],
                            )
                          : const Text('Connect to router'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Make sure your device is connected to the '
                      'router’s Wi-Fi network.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
