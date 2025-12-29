import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppConfig {
  final String baseUrl;

  const AppConfig({
    required this.baseUrl,
  });
}

/// Android emulator → host makine
const defaultAppConfig = AppConfig(
  baseUrl: 'http://10.0.2.2:8080',
);

/// Global config provider
final appConfigProvider = Provider<AppConfig>((ref) {
  return defaultAppConfig;
});
