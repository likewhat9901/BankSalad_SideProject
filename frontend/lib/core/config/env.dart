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

  /// 현재 환경 감지
  static String get environment {
    return kDebugMode ? 'development' : 'production';
  }
}