import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'logger_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  String? _token;
  String? get token => _token;

  /// 백그라운드 메시지 핸들러 (main 함수 밖에서 호출해야 함)
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    LoggerService.info('백그라운드 메시지 수신: ${message.notification?.title}');
  }

  /// FCM 초기화
  Future<void> init() async {
    try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // 권한 요청
        NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        );

        LoggerService.info('🔔 알림 권한 상태: ${settings.authorizationStatus}');

        // FCM 토큰 가져오기
        _token = await messaging.getToken();
        LoggerService.info('🔑 FCM Token: $_token');

        // 포그라운드 메시지 수신 리스너
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);

        // 알림 탭으로 앱 열릴 때 (백그라운드에서)
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

        // 앱 종료 상태에서 알림 탭으로 시작될 때
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
            _onMessageOpenedApp(initialMessage);
        }

        LoggerService.info('FCM 초기화 완료');
    } catch (e, stackTrace) {
        LoggerService.error('FCM 초기화 실패', e, stackTrace);
    }
  } 

  void _onForegroundMessage(RemoteMessage message) {
    LoggerService.info('📩 포그라운드 메시지: ${message.notification?.title}');
    // TODO: 필요시 로컬 알림 표시
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    LoggerService.info('👆 알림 탭으로 앱 열림: ${message.notification?.title}');
    // TODO: 특정 화면으로 이동 로직
  }
}