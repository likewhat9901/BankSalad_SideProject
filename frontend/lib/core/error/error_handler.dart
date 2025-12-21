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
      
      // 웹에서는 콘솔에 상세 정보 출력
      if (kIsWeb) {
        printWebError(
          'FlutterError',
          details.exception.toString(),
          details.library,
          details.context?.toString(),
          details.stack?.toString(),
        );
      }
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
      
      // 웹에서는 콘솔에 출력
      if (kIsWeb) {
        printWebError(
          'PlatformError',
          error.toString(),
          null,
          null,
          stack?.toString(),
        );
      }
      
      return true; // 에러 처리 완료
    };
  }
  
  /// 모든 에러 핸들러 설정 (한 번에 호출)
  static void setupAll() {
    setupFlutterErrorHandler();
    setupPlatformErrorHandler();
  }
  
  /// 웹 콘솔에 에러 출력 (포맷팅)
  static void printWebError(  // _printWebError → printWebError
    String type,
    String error,
    String? library,
    String? context,
    String? stack,
  ) {
    print('❌❌❌ $type 발생 ❌❌❌');
    print('📍 Error: $error');
    if (library != null) {
      print('📍 Library: $library');
    }
    if (context != null) {
      print('📍 Context: $context');
    }
    if (stack != null) {
      print('📍 Stack: $stack');
    }
    print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
  }
}