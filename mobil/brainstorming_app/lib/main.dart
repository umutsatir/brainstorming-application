import 'package:brainstorming_app/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  runApp(const ProviderScope(child: BrainstormingApp()));
}

class BrainstormingApp extends StatelessWidget {
  const BrainstormingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brainstorming App',
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),   // Uygulama açılınca splash → profile check → login
    );
  }
}
