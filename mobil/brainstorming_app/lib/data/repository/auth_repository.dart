import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/models/user.dart';
import '../core/api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  /// (Opsiyonel) Profil getirme – token varsa `Authorization` header’ına set eder.
  /// Bunu auto-login olarak kullanmak zorunda değilsin; istediğin ekranda manuel çağırabilirsin.
  Future<AppUser?> loadProfile() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    _apiClient.setAuthToken(token);

    final response = await _apiClient.get('/auth/me');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return AppUser.fromJson(userJson);
    }

    // Token bozuktur → temizle
    await logout();
    return null;
  }

  /// POST /api/auth/login
  /// response ör: { "user": { ... }, "token": "xxx" }
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
  
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;

      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw Exception('Invalid login response format');
      }

      final user = AppUser.fromJson(userJson);
      

      // Token’ı sakla ve ApiClient’e tanıt
      await _storage.write(key: _tokenKey, value: token);
      _apiClient.setAuthToken(token);

      return user;
    }

    // 4xx hatası – backend "message" döküyorsa onu kullan
    final body = response.data;
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Login failed: ${response.statusCode}';
    throw Exception(message);
  }

  /// POST /api/auth/register
  /// response ör: { "user": { ... }, "token": "xxx" } ya da { "token": "...", "user": {...} }
  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data as Map<String, dynamic>;

      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>? ?? data['userData'];

      if (token == null || userJson == null) {
        throw Exception('Invalid register response format');
      }

      final user = AppUser.fromJson(userJson);

      // Yeni kayıt olduysa da genelde direkt login olmuş gibi token verilir
      await _storage.write(key: _tokenKey, value: token);
      _apiClient.setAuthToken(token);

      return user;
    }

    final body = response.data;
    final message = body is Map && body['message'] != null
        ? body['message'].toString()
        : 'Register failed: ${response.statusCode}';
    throw Exception(message);
  }

  /// Logout:
  /// - Backend /api/auth/logout varsa ona istek atıyoruz (fail etse bile)
  /// - Sonra her halükarda local token’ı siliyoruz
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Logout çağrısı hata verse bile local’den silmeye devam
    }

    await _storage.delete(key: _tokenKey);
    _apiClient.setAuthToken(null);
  }
}

/// Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  const storage = FlutterSecureStorage();
  return AuthRepository(apiClient, storage);
});
