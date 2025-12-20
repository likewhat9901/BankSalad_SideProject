import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../logger/logger_service.dart';
import '../routing/push_router.dart';


/// Firebase Cloud Messaging (FCM) 서비스
/// FCM : 서버가 앱이 꺼져 있어도 사용자 기기에 신호를 보내는 공식 통로
class FCMService {
  // ========== 싱글톤 인스턴스 ==========
  // 여러번 생성되면 리스너 중복, 로그 중복, 알림 처리 꼬임 발생
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // ========== 토큰 정보 ==========
  // 디바이스 고유 식별자
  String? _token;
  String? get token => _token;

  // ========== 백그라운드 메시지 핸들러 ==========
  /// 백그라운드 메시지 핸들러 (main 함수 밖에서 호출해야 함)
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    LoggerService.info('FCM', '백그라운드 메시지 수신: ${message.notification?.title}');
  }

  // ========== FCM 초기화 ==========
  Future<void> init() async {
    try {
        // FirebaseMessaging 인스턴스 생성 (푸시받을 준비 시작)
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // 1. 알림 권한 요청 (ios 필수, android 대부분 자동 허용)
        NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        );
        LoggerService.info('FCM', '알림 권한 상태: ${settings.authorizationStatus}');

        // 2. FCM 토큰 발급 (토근: 디바이스 고유 식별자)
        _token = await messaging.getToken();
        LoggerService.info('FCM', 'FCM Token: $_token');

        // TODO: 로그인 이후 서버로 토큰 전송 (userId 매핑)

        // 3. 토큰 갱신 대응 (중요)
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _token = newToken;
          LoggerService.info('FCM', 'FCM Token 갱신: $newToken');

          // TODO: 서버에 토큰 재등록
        });

        // ========== 앱 상태에 따른 다른 리스너 ==========

        // 4-1. 포그라운드(앱 실행 중) 메시지 수신 리스너
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);

        // 4-2. 백그라운드(앱 꺼져 있음 )에서 알림 탭으로 앱 열림
        FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

        // 4-3. 앱 종료 상태에서 알림 탭으로 앱 시작
        RemoteMessage? initialMessage = await messaging.getInitialMessage();
        // 앱 종료 상태에서 알림 탭으로 앱 시작 시 메시지 처리
        if (initialMessage != null) {
            _onMessageOpenedApp(initialMessage);
        }

        LoggerService.info('FCM', 'FCM 초기화 완료');
    } catch (e, stackTrace) {
        LoggerService.error('FCM', 'FCM 초기화 실패', e, stackTrace);
    }
  } 

  // ========== 포그라운드 메시지 핸들러 ==========
  // 기본 알림 없이 앱 내에서 UI 알림 처리
  void _onForegroundMessage(RemoteMessage message) {
    LoggerService.info('FCM', '포그라운드 메시지: ${message.notification?.title}');

    // TODO: 필요시 로컬 알림 표시
    // TODO: In-App 알림 UI (Snackbar, Dialog 등)
  }

  // ========== (백그라운드) 알림 탭으로 앱 열림 핸들러 ==========
  void _onMessageOpenedApp(RemoteMessage message) {
    LoggerService.info('FCM', '알림 탭으로 앱 열림: ${message.notification?.title}');

    //서버가 보낸 데이터 (앱용)
    final data = message.data;

    if (data.isEmpty) return;

    PushRouter.handle(data);
  }
}