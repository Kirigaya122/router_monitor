import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'router_xml.dart';

class RouterClient {
  static const String baseUrl = 'http://192.168.1.1';
  static const String realm = 'Highwmg';
  static const String qop = 'auth';
  static const String digestUri = '/cgi/xml_action.cgi';

  // Hardcoded token from the R023 firmware's PostXml() function.
  static const String csrfToken = 'hfiehifejfklihefiuehflejhfueihfeuihfeui';

  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();
  final Random _random = Random.secure();

  String? _username;
  String? _password;
  String? _nonce;
  int _nonceCount = 1;

  RouterClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': '*/*'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  String _md5(String value) {
    return md5.convert(value.codeUnits).toString();
  }

  String _nextCnonce() {
    final random = List<int>.generate(16, (_) => _random.nextInt(256));

    return _md5('${random.join()}${DateTime.now().millisecondsSinceEpoch}')
        .substring(0, 16);
  }

  String _nextNonceCount() {
    final value = _nonceCount.toRadixString(16).padLeft(8, '0');
    _nonceCount++;
    return value;
  }

  String _digestResponse({
    required String method,
    required String uri,
    required String nonce,
    required String cnonce,
    required String nc,
  }) {
    final ha1 = _md5('$_username:$realm:$_password');
    final ha2 = _md5('$method:$uri');

    return _md5('$ha1:$nonce:$nc:$cnonce:$qop:$ha2');
  }

  String _authorization(String method) {
    final nonce = _nonce;
    if (nonce == null) {
      throw StateError('Authenticate first.');
    }

    final cnonce = _nextCnonce();
    final nc = _nextNonceCount();

    final response = _digestResponse(
      method: method,
      uri: digestUri,
      nonce: nonce,
      cnonce: cnonce,
      nc: nc,
    );

    return 'Digest username="$_username", '
        'realm="$realm", '
        'nonce="$nonce", '
        'uri="$digestUri", '
        'response="$response", '
        'qop=$qop, nc=$nc, cnonce="$cnonce"';
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _username = username;
    _password = password;
    _nonceCount = 1;

    final challengeResponse = await _dio.get<String>(
      '/login.cgi',
      options: Options(responseType: ResponseType.plain),
    );

    final challengeValues = challengeResponse.headers['www-authenticate'];

    final challenge = challengeValues
        ?.map((value) => value.trim())
        .firstWhere((value) => value.startsWith('Digest '), orElse: () => '');

    if (challenge == null || challenge.isEmpty) {
      throw StateError('No Digest challenge found in response headers.');
    }

    final realmMatch = RegExp(r'realm="([^"]+)"').firstMatch(challenge);
    final nonceMatch = RegExp(r'nonce="([^"]+)"').firstMatch(challenge);
    final qopMatch = RegExp(r'qop="([^"]+)"').firstMatch(challenge);

    if (realmMatch == null || nonceMatch == null || qopMatch == null) {
      throw StateError('Could not parse Digest challenge.');
    }

    if (realmMatch.group(1) != realm || qopMatch.group(1) != qop) {
      throw StateError('Unexpected router Digest parameters.');
    }

    _nonce = nonceMatch.group(1);

    final nonce = _nonce!;
    final cnonce = _nextCnonce();
    final nc = _nextNonceCount();

    final loginResponse = _digestResponse(
      method: 'GET',
      uri: '/cgi/xml_action.cgi',
      nonce: nonce,
      cnonce: cnonce,
      nc: nc,
    );

    final loginUri = Uri(
      path: '/login.cgi',
      queryParameters: {
        'Action': 'Digest',
        'username': username,
        'realm': realm,
        'nonce': nonce,
        'response': loginResponse,
        'qop': qop,
        'cnonce': cnonce,
        'nc': nc,
        'temp': 'marvell',
      },
    );

    final response = await _dio.get<String>(
      loginUri.toString(),
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Authorization': _authorization('GET'),
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ),
    );

    final loginStatusValues = response.headers['www-authenticate'] ?? [];

    final loginStatus = loginStatusValues
        .map((value) => value.trim())
        .firstWhere((value) => value.contains('status='), orElse: () => '');

    if (loginStatus.contains('status=0') == true) {
      return true;
    }

    throw StateError(
      'Login not confirmed. HTTP ${response.statusCode}; '
      'router status: $loginStatus',
    );
  }

  Future<Response<String>> postXml(
    String objPath,
    String objMethod, {
    Map<String, String>? params,
    bool retried = false,
  }) async {
    final xml = RouterXml.buildRequest(objPath, objMethod, params: params);

    final response = await _dio.post<String>(
      '/xml_action.cgi?method=set',
      data: xml,
      options: Options(
        responseType: ResponseType.plain,
        headers: {
          'Authorization': _authorization('POST'),
          'csrftoken': csrfToken,
        },
      ),
    );

    if (!retried && _needsReauth(response)) {
      final username = _username;
      final password = _password;

      if (username != null && password != null) {
        // The router session expired. Re-authenticate silently and
        // retry the request once so the user never notices.
        await login(username: username, password: password);
        return postXml(objPath, objMethod, params: params, retried: true);
      }
    }

    return response;
  }

  bool _needsReauth(Response<String> response) {
    if (response.statusCode == 401) return true;

    final body = response.data ?? '';

    // The R023 firmware uses error_cause=5 to signal "no authority".
    // Its own JavaScript handles this by clearing the auth header and
    // forcing a fresh login on the next request.
    return RegExp(r'<error_cause>\s*5\s*</error_cause>').hasMatch(body);
  }

  Future<void> logout() async {
    try {
      await _dio.get<String>('/xml_action.cgi?Action=logout');
    } catch (_) {
      // Return gracefully even if the router is unreachable.
    }

    _username = null;
    _password = null;
    _nonce = null;
    _nonceCount = 1;

    await _cookieJar.deleteAll();
  }

  void close() {
    _dio.close(force: true);
  }
}
