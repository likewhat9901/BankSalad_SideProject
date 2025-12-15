import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;      // 웹 여부 체크용 상수(kIsWeb)
import 'package:firebase_core/firebase_core.dart';        // Firebase 초기화
import 'package:firebase_messaging/firebase_messaging.dart'; // FCM(푸시 알림)
import 'domains/home/home_screen.dart';                   // 홈 탭 화면
import 'domains/transaction/transactions_screen.dart';    // 거래내역 탭 화면
import 'domains/analysis/overspending_screen.dart';       // 과소비 분석 탭 화면
import 'core/notification/fcm_service.dart';              // FCM 서비스 (백그라운드/포그라운드 처리)
import 'core/logger/logger_service.dart';                 // 공통 로깅 서비스

// 앱 진입점
void main() async {
  // Flutter 엔진과 위젯 바인딩 초기화 (비동기 초기화 전에 필수)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 웹이 아닐 때만 Firebase 초기화
  if (!kIsWeb) {
    try {
      // Firebase 초기화
      await Firebase.initializeApp();

      // FCM 백그라운드 메시지 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(FCMService.backgroundHandler);
      // FCM 초기화
      await FCMService().init();
    } catch (e) {
      // Firebase 초기화 실패해도 앱은 실행
      LoggerService.error('Firebase 초기화 실패 (웹 환경일 수 있음): $e');
    }
  }
  // Flutter 앱 실행
  runApp(const MyApp());
}

// 앱 전체를 감싸는 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '뱅크샐러드 앱',     // 앱 타이틀 (OS, 히스토리 등에 보일 수 있음)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00D4AA), // 뱅크샐러드 민트색
          brightness: Brightness.light,      // 밝은 테마
        ),
        useMaterial3: true,                 // Material3 사용
        appBarTheme: const AppBarTheme(     // 앱바 테마
          centerTitle: true,                // 제목 중앙 정렬
          elevation: 0,                     // 그림자 없음
        ),
      ),
      home: const MainNavigationPage(),    // 메인 네비게이션 페이지
    );
  }
}

// 하단 네비게이션(3탭)을 제공하는 메인 페이지
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  // 현재 선택된 탭 인덱스 (0: 홈, 1: 거래내역, 2: 과소비 분석)
  int _selectedIndex = 0;

  // 각 탭에서 보여줄 화면들 리스트
  final List<Widget> _screens = const [
    HomeScreen(),           // 0번 탭: 홈
    TransactionsScreen(),   // 1번 탭: 거래내역
    OverspendingScreen(),   // 2번 탭: 과소비 분석
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 인덱스에 해당하는 화면을 body 에 표시
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,         // 선택된 탭 인덱스
        onDestinationSelected: (index) {      // 탭 변경 콜백 (index: 선택된 탭 인덱스)
          setState(() {
            _selectedIndex = index;           // 상태 업데이트 → 화면 전환
          });
        },
        destinations: const [             // 하단 네비게이션 탭 목록(index 순서대로 탭 표시)
          NavigationDestination(
            icon: Icon(Icons.home_outlined),   // 홈 아이콘
            selectedIcon: Icon(Icons.home),     // 선택된 홈 아이콘
            label: '홈',                         // 탭 라벨
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined), // 거래내역 아이콘
            selectedIcon: Icon(Icons.receipt_long),   // 선택된 거래내역 아이콘
            label: '거래내역',                         // 탭 라벨
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined), // 과소비 분석 아이콘
            selectedIcon: Icon(Icons.trending_up),   // 선택된 과소비 분석 아이콘
            label: '과소비 분석',                     // 탭 라벨
          ),
        ],
      ),
    );
  }
}