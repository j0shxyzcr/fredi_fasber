import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// Android emulator: http://10.0.2.2:8000
// Chrome: --dart-define=API_BASE_URL=http://localhost:8000
// Dispositivo físico: --dart-define=API_BASE_URL=http://IP_DE_TU_PC:8000
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

class ApiException implements Exception {
  final String message;
  final int status;
  const ApiException(this.message, this.status);
  @override
  String toString() => message;
}

class Api {
  Api._();
  static final Api instance = Api._();
  final _storage = const FlutterSecureStorage();
  String? _token;

  Future<void> init() async => _token = await _storage.read(key: 'fnaf_jwt');
  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'fnaf_jwt');
  }

  Future<dynamic> request(String method, String path, [Map<String, dynamic>? body]) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    http.Response response;
    try {
      final uri = Uri.parse('$apiBaseUrl$path');
      response = await (method == 'POST'
          ? http.post(uri, headers: headers, body: jsonEncode(body ?? {}))
          : http.get(uri, headers: headers)).timeout(const Duration(seconds: 18));
    } catch (_) {
      throw const ApiException('No se pudo conectar con FastAPI. Revisa IP, Wi-Fi y servidor.', 0);
    }
    dynamic data;
    try {
      data = response.body.isEmpty ? {} : jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException('El servidor devolvió una respuesta inválida (${response.statusCode})', response.statusCode);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;
      throw ApiException(detail is String ? detail : 'Error ${response.statusCode}', response.statusCode);
    }
    return data;
  }

  Future<Map<String, dynamic>> _auth(String path, Map<String, dynamic> fields) async {
    final result = Map<String, dynamic>.from(await request('POST', path, fields) as Map);
    _token = result['access_token'] as String;
    await _storage.write(key: 'fnaf_jwt', value: _token);
    return Map<String, dynamic>.from(result['user'] as Map);
  }

  Future<Map<String, dynamic>> login(String email, String password) =>
      _auth('/auth/login', {'email': email, 'password': password});
  Future<Map<String, dynamic>> register(String username, String email, String password) =>
      _auth('/auth/register', {'username': username, 'email': email, 'password': password});
  Future<Map<String, dynamic>?> whoAmI() async {
    if (_token == null) return null;
    try {
      return Map<String, dynamic>.from(await request('GET', '/auth/me') as Map);
    } catch (error) {
      if (error is ApiException && error.status == 401) await logout();
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> list(String path) async {
    final result = await request('GET', path) as List;
    return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async =>
      Map<String, dynamic>.from(await request('POST', path, data) as Map);
}
