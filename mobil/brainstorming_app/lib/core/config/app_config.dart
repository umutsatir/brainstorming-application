// lib/core/config/app_config.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final String baseUrl;

  const AppConfig({required this.baseUrl});
}

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig(
    baseUrl: "http://10.0.2.2:8080/api",
  );
});
