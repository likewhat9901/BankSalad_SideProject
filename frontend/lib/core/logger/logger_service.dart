import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: SimplePrinter(
      colors: true,
      printTime: true,
    ),
    level: Level.debug,
    output: null, // 기본 출력 사용
  );

  // ========== 로깅 메서드 ==========

  static void debug(String tag,String message) {
    _logger.d('[$tag]: $message');
  }

  static void info(String tag,String message) {
    _logger.i('[$tag]: $message');
  }

  static void warning(String tag,String message) {
    _logger.w('[$tag]: $message');
  }

  static void error(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('[$tag]: $message', error: error, stackTrace: stackTrace);
  }
}