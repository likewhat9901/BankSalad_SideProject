import 'package:flutter/foundation.dart';
import '../logger/logger_service.dart';

/// 전역 에러 핸들러 설정
class ErrorHandler {
  /// Flutter 에러 핸들러 설정
  static void setupFlutterErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // 개발 모드에서는 Flutter 기본 에러 표시
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // LoggerService로 기록
      LoggerService.error(
        'FlutterError',
        '${details.exception}',
        details.exception,
        details.stack,
      );
    };
  }
  
  /// 플랫폼 에러 핸들러 설정
  static void setupPlatformErrorHandler() {
    PlatformDispatcher.instance.onError = (error, stack) {
      LoggerService.error(
        'PlatformError',
        '플랫폼 에러 발생: $error',
        error,
        stack,
      );
      return true; // 에러 처리 완료
    };
  }
  
  /// 모든 에러 핸들러 설정 (한 번에 호출)
  static void setupAll() {
    setupFlutterErrorHandler();
    setupPlatformErrorHandler();
  }
}