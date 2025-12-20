import 'package:flutter/foundation.dart';

/// 환경 변수 읽기 헬퍼
class Env {

  // ========== 환경 변수 읽기 ==========

  /// 환경 변수 읽기 (String)
  static String getString(String key, {String defaultValue = ''}) {
    return String.fromEnvironment(key, defaultValue: defaultValue);
  }
  
  /// 환경 변수 읽기 (bool)
  static bool getBool(String key, {bool defaultValue = false}) {
    final value = getString(key);
    if (value.isEmpty) return defaultValue;
    return value.toLowerCase() == 'true';
  }
  
  /// 환경 변수 읽기 (int)
  static int getInt(String key, {int defaultValue = 0}) {
    final value = getString(key);
    if (value.isEmpty) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }
  
  // ========== 환경 감지 ==========

  /// 현재 환경 감지 (수동 환경변수 > 자동 감지 > default: development/production)
  static String get environment {
    // 1. ENVIRONMENT 환경 변수 우선 사용
    final env = getString('ENVIRONMENT');
    if (env.isEmpty) {
      // 2. kDebugMode 기반 자동 감지
      return kDebugMode ? 'development' : 'production';
    }
    // 3. ENVIRONMENT 환경 변수 반환
    return env;
  }
}