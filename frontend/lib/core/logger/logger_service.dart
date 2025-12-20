import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: kIsWeb 
      ? PrettyPrinter(
          methodCount: 0, // 스택 트레이스 줄 수 (0 = 없음)
          errorMethodCount: 8,
          lineLength: 120,
          colors: false, // 웹에서는 색상 비활성화
          printEmojis: false,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        )
      : SimplePrinter(
          colors: true,
          printTime: true,
        ),
    level: Env.environment == 'production' 
      ? Level.warning  // 프로덕션: warning 이상만
      : Level.debug,   // 개발: 모든 로그
    output: kIsWeb ? _WebOutput() : null, // 웹 전용 출력
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

// 웹 전용 출력 클래스
class _WebOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // 운영(release) 웹에서는 콘솔 출력 최소화
    if (kReleaseMode) return;

    for (final line in event.lines) {
      debugPrint(line);
    }
  }
}