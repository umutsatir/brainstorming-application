import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../data/repository/auth_repository.dart';

/// Ekranların dinleyeceği auth state
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const initial = AuthState();
}

/// Artık StateNotifier değil, Notifier kullanıyoruz (Riverpod v3)
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;

  @override
  AuthState build() {
    // Provider dışından gelecek repository
    _authRepository = ref.read(authRepositoryProvider);
    return AuthState.initial;
  }

  /// LOGIN
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
        errorMessage: null,
      );

      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// SIGN UP (register)
  Future<AppUser?> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );

      state = state.copyWith(
        isLoading: false,
        user: user,
        errorMessage: null,
      );

      return user;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.initial;
  }
}

/// Eski StateNotifierProvider yerine bunu kullanıyoruz
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
