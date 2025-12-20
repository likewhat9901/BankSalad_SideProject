import 'package:url_launcher/url_launcher.dart';        // 외부 앱 실행 / 웹 링크 열기용 플러그인
import '../../logger/logger_service.dart';              // 로깅 서비스

class AppLauncherService {
  // ========== 뱅크샐러드 패키지 정보 ==========
  static const String _bankSaladPackage = 'com.rainist.banksalad2';

  // ========== 뱅크샐러드 플레이스토어 링크 ==========
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rainist.banksalad2';
  
  // ========== 앱 직접 실행 링크 (market://) ==========
  static const String _marketUrl = 'market://details?id=$_bankSaladPackage';

  // ========== 뱅크샐러드 앱 열기 ==========
  static Future<void> openBankSalad() async {
    LoggerService.info('AppLauncher', '뱅크샐러드 앱 실행 시도');
    
    try {
      // 먼저 market:// 링크 시도 (앱이 설치되어 있으면 앱 열기)
      final marketUri = Uri.parse(_marketUrl);
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri);
        LoggerService.info('AppLauncher', '뱅크샐러드 앱 실행 완료');
        return;
      }
      
      // market://이 안되면 플레이스토어 웹 링크로
      final webUri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        LoggerService.info('AppLauncher', '플레이스토어 링크로 이동');
      } else {
        throw Exception('링크를 열 수 없습니다');
      }
    } catch (e, stackTrace) {
      LoggerService.error('AppLauncher', '뱅크샐러드 앱 실행 실패', e, stackTrace);
      rethrow;
    }
  }
}