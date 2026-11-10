import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStore {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  static const _usernameKey = 'router_username';
  static const _passwordKey = 'router_password';

  Future<void> save({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<({String username, String password})?> read() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);

    if (username == null || password == null) return null;

    return (username: username, password: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}
