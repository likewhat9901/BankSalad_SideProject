import 'package:flutter/material.dart';
import 'core/config/app_theme.dart';                                // 앱 테마
import 'core/routing/app_route.dart';                               // 앱 라우트
import 'core/app_initializer.dart';                                 // 앱 초기화
import 'core/error/error_handler.dart';                             // 전역 에러 핸들러

import 'domains/home/home_screen.dart';                             // 홈 탭 화면
import 'domains/transaction/transactions_screen.dart';              // 거래내역 탭 화면
import 'domains/analysis/overspending/overspending_screen.dart';    // 과소비 분석 탭 화면
import 'domains/savings/savings_screen.dart';                       // 절약 기회 분석 탭 화면

/// 앱 진입점 (async 필수: Firebase 초기화가 비동기이기 때문)
void main() async {
  // Flutter 엔진과 위젯 시스템을 먼저 준비 (비동기 초기화(await Firebase.initializeApp()) 전에 필수)
  // 없으면 크래시 or 알 수 없는 에러
  WidgetsFlutterBinding.ensureInitialized();

  // 전역 에러 핸들러 설정
  ErrorHandler.setupAll();

  // 앱 초기화 (Firebase 초기화, FCM 초기화 등)
  await AppInitializer.init();
  // Flutter 앱 실행 (const -> 같은 인스턴스를 재사용)
  runApp(const MyApp());
}

// 앱 전체를 감싸는 루트 위젯
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    // Flutter 앱의 뼈대 (라우팅, 테마, 다 여기서 관리)
    return MaterialApp(
      title: '뱅크샐러드 앱',     // 앱의 논리적 이름 (OS 앱 목록, 웹 타이틀에 사용)
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.root,
      routes: {
        AppRoutes.root: (context) => const MainNavigationPage(),
      },
      onGenerateRoute: AppRoutes.generateRoute,
      navigatorKey: AppRoutes.navigatorKey,
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

  // 각 탭에서 보여줄 화면들 리스트 (const -> 화면 재사용 가능)
  final List<Widget> _screens = const [
    HomeScreen(),             // 0번 탭: 홈
    TransactionsScreen(),     // 1번 탭: 거래내역
    OverspendingScreen(),     // 2번 탭: 과소비 분석
    SavingsScreen(),          // 3번 탭: 절약 기회 분석
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 현재 선택된 인덱스에 해당하는 화면을 body 에 표시
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      // 하단 네비게이션 바 (Material Design 3 스타일)
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
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: '절약',
          ),
        ],
      ),
    );
  }
}