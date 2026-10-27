import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8001/api';
    }
    return 'http://127.0.0.1:8001/api';
  }

  static Uri mediaUri(String value) {
    final uri = Uri.parse(value);
    if (uri.hasScheme) return uri;
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: value.startsWith('/') ? value : '/$value',
      query: null,
      fragment: null,
    );
  }
}
