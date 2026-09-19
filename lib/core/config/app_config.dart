import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const String _apiBaseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// NestJS API base URL.
  /// Override with --dart-define=API_BASE_URL=...
  /// Android emulator uses http://10.0.2.2:3000 to reach the host machine.
  static String get apiBaseUrl {
    if (_apiBaseUrlFromEnv.isNotEmpty) {
      return _apiBaseUrlFromEnv;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.1.180:3000';
    }
    return 'http://localhost:3000';
  }

  /// Mapbox public access token (`pk....`).
  /// Pass with --dart-define=MAPBOX_ACCESS_TOKEN=...
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );
}
