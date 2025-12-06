import 'package:external_app_launcher/external_app_launcher.dart';
import 'logger_service.dart';

class AppLauncherService {
  static const String _bankSaladPackage = 'com.rainist.banksalad2';

  /// 뱅크샐러드 앱 열기
  static Future<void> openBankSalad() async {
    LoggerService.info('뱅크샐러드 앱 실행 시도');
    try {
      await LaunchApp.openApp(
        androidPackageName: _bankSaladPackage,
        openStore: true,
      );
      LoggerService.info('뱅크샐러드 앱 실행 완료');
    } catch (e, stackTrace) {
      LoggerService.error('뱅크샐러드 앱 실행 실패', e, stackTrace);
      rethrow;
    }
  }
}