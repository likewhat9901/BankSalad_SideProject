import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification/fcm_service.dart';
import 'logger/logger_service.dart';

class AppInitializer {
  static Future<void> init() async {

    // 웹이 아니면 Firebase/FCM 초기화
    if (!kIsWeb) {
      try {
        await Firebase.initializeApp();

        // 백그라운드 FCM 핸들러 등록
        // FCM : 서버가 앱이 꺼져 있어도 사용자 기기에 신호를 보내는 공식 통로
        // static 함수여야 한다 (Flutter 제약)
        FirebaseMessaging.onBackgroundMessage(
          FCMService.backgroundHandler,
        );

        // 포그라운드 FCM 초기화 (포그라운드 알림, 토큰 발급, 권한 요청, 리스너 등록 등)
        await FCMService().init();
      } catch (e) {
        // Firebase 초기화 실패해도 앱은 실행 (실패 기록만 남김)
        LoggerService.error('Firebase', 'Firebase 초기화 실패 (웹 환경일 수 있음): $e', e);
      }
    }
  }
}
