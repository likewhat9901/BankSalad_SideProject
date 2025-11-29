import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger(
    printer: SimplePrinter(
      colors: true,
      printTime: true,
    ),
    level: Level.debug,
  );

  static void debug(String message) => _logger.d('🐛 $message');
  static void info(String message) => _logger.i('💡 $message');
  static void warning(String message) => _logger.w('⚠️ $message');
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('❌ $message', error: error, stackTrace: stackTrace);
  }
}