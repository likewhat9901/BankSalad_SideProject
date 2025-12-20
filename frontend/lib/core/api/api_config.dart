import 'package:flutter/foundation.dart';
import '../config/env.dart';

class ApiConfig {
  // ========== 상수 정의 ==========

  /// 요청 타임아웃 설정
  static const Duration timeout = Duration(seconds: 10);
  
  /// 프로덕션 서버 URL (Railway)
  static const String _productionUrl = 'https://banksalad-backend.up.railway.app';

  // ========== 개발 환경 URL ==========

  /// 개발용 로컬 서버 URL (플랫폼별)
  static String get _developmentUrl {
    // 웹: localhost
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // 모바일 (안드로이드 에뮬레이터): 10.0.2.2
    return 'http://10.0.2.2:8000';
  }

  // ========== Base URL 결정 로직 ==========

  /// baseUrl 가져오기 (우선순위: 환경 변수 > 웹 환경 > Debug/Release 모드)
  static String get baseUrl {
    // 1순위: 환경 변수로 강제 지정된 경우
    final apiUrlFromEnv = Env.getString('API_URL');
    if (apiUrlFromEnv.isNotEmpty) {
      return apiUrlFromEnv;
    }

    // 2순위: 웹 환경은 항상 프로덕션 서버 사용
    if (kIsWeb) {
      return _productionUrl;
    }

    // 3순위: 모바일 환경
    // Debug 모드 → 개발 서버, Release 모드 → 프로덕션 서버
    return Env.environment == 'development' ? _developmentUrl : _productionUrl;
  }
}