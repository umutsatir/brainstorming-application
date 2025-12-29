import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart'; // kDebugMode

import '../controller/auth_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

import '../../../core/enums/user_role.dart';
import '../../../core/models/user.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // 🔹 Debug için seçilebilir rol (sadece kDebugMode'da kullanılacak)
  UserRole _debugSelectedRole = UserRole.teamMember;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // 🔹 Login state değişince navigation + error snackbar
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Login başarılı → dashboard'a git
      if (previous?.user != next.user && next.user != null) {
        final originalUser = next.user!;

        // 🔹 Debug modda rolü override ediyoruz
        final AppUser effectiveUser = kDebugMode
            ? AppUser(
                id: originalUser.id,
                name: originalUser.name,
                email: originalUser.email,
                role: _debugSelectedRole,
                status: originalUser.status,
                createdAt: originalUser.createdAt,
                updatedAt: originalUser.updatedAt,
              )
            : originalUser;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(user: effectiveUser),
          ),
        );
      }

      // Hata varsa snackbar göster (errorMessage kullanıyoruz!)
      if (next.errorMessage != null &&
          next.errorMessage!.isNotEmpty &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(next.errorMessage!)),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '6-3-5 Brainstorming',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with your account provided by the Event Manager.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // E-mail
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) {
                        return 'E-mail is required';
                      }
                      if (!v.contains('@')) {
                        return 'Please enter a valid e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // 🔹 DEBUG ROLE DROPDOWN (Sadece debug build'de)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: _debugSelectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Debug role override',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.eventManager,
                          child: Text('Event Manager'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.teamLeader,
                          child: Text('Team Leader'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.teamMember,
                          child: Text('Team Member'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _debugSelectedRole = val;
                          });
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _onLoginPressed,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
