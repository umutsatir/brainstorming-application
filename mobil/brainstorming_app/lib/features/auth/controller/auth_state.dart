import '../../../core/models/user.dart';

class AuthState {
  final bool isLoading;
  final AppUser? user;
  final String? token;
  final String? error; // 🔥 BURADA error alanı var

  const AuthState({
    this.isLoading = false,
    this.user,
    this.token,
    this.error,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    bool? isLoading,
    AppUser? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      // error her çağrıda override edilsin diye direkt error kullanıyoruz
      error: error,
    );
  }
}
