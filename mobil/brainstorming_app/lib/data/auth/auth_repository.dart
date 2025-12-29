import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/models/user.dart';
import '../../data/core/api_client.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  /// Uygulama açılışında token varsa ApiClient'e set etmek için çağrılabilir
  Future<AppUser?> loadProfile() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    _apiClient.setAuthToken(token);

    final response = await _apiClient.get('/api/auth/profile');

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return AppUser.fromJson(userJson);
    }

    // Token bozuktur, temizleyelim
    await logout();
    return null;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;

      // Backend örneğin:
      // { "user": { ... }, "token": "xxx" }
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

    // 4xx hatası
    throw Exception(
      'Login failed: ${response.statusCode} ${response.data}',
    );
  }

  Future<void> logout() async {
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
