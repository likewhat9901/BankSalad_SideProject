import 'package:flutter/foundation.dart';

class ApiConfig {
  static const Duration timeout = Duration(seconds: 10);

  // 배포된 백엔드 URL (Railway) - 나중에 실제 URL로 변경 필요
  static const String _productionUrl = 'https://your-backend.railway.app';
  
  // 개발용 로컬 서버 URL
  static const String _developmentUrl = 'http://10.0.2.2:8000';

  static String get baseUrl {
    // 환경 변수로 강제 지정 가능
    const String? apiUrl = String.fromEnvironment('API_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }

    // Debug 모드 = 개발 중 → 로컬 서버
    // Release 모드 = 프로덕션 → Railway 서버
    return kDebugMode ? _developmentUrl : _productionUrl;
  }
}