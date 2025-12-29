import 'package:flutter/material.dart';
import '../../domains/auth/login_screen.dart';
import '../../domains/auth/signup_screen.dart';
import '../../domains/transaction/transaction.dart';
import '../../domains/transaction/transaction_detail_screen.dart';
import '../../domains/analysis/overspending/overspending_rules_screen.dart';
import '../../domains/analysis/overspending/overspending_rules_edit_screen.dart';
import '../../domains/transaction/filtered_transactions_screen.dart';
import '../../domains/home/inquiry_screen.dart';
import '../logger/logger_service.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String inquiry = '/inquiry';
  static const String transactionDetail = '/transaction/detail';
  static const String overspendingRules = '/overspending/rules';
  static const String overspendingRuleEdit = '/overspending/rule/edit';
  static const String filteredTransactions = '/transactions/filtered';

  // ========== Navigator ==========
  // 전역 네비게이션 키 (context 없이 네비게이션 가능)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// context 없이 라우트 이동
  static void pushNamed(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  // ========== Helpers ==========
  static MaterialPageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  static MaterialPageRoute _error(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }

  /// 라우트 생성 함수 (context 필수)
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    try {
      switch (settings.name) {
        case login:
          return _page(const LoginScreen());

        case signup:
          return _page(const SignupScreen());

        case AppRoutes.inquiry:
          return _page(const InquiryScreen());

        case transactionDetail:
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return _error('거래내역 정보가 없습니다');
          }

          final transaction = args['transaction'];
          if (transaction == null) {
            return _error('거래내역 정보가 없습니다');
          }

          if (transaction is! Transaction) {
            return _error('거래내역 데이터 형식이 올바르지 않습니다');
          }

          return _page(TransactionDetailScreen(
            transaction: transaction,
            onUpdate: args['onUpdate'] as VoidCallback?,
          ));
        
        case filteredTransactions:
          final args = settings.arguments as Map<String, dynamic>?;
          if (args == null) {
            return _error('필터 정보가 없습니다');
          }
          final title = args['title'];
          final filters = args['filters'];
          
          if (title == null || title is! String) {
            return _error('제목 정보가 올바르지 않습니다');
          }
          
          if (filters == null || filters is! Map<String, dynamic>) {
            return _error('필터 정보가 올바르지 않습니다');
          }
          return _page(FilteredTransactionsScreen(
            title: title,
            filters: filters,
          ));

        case overspendingRules:
          return _page(const OverspendingRulesScreen());

        case overspendingRuleEdit:
          final args = settings.arguments as Map<String, dynamic>?;
          final onSave = args?['onSave'] as Function(Map<String, dynamic>)?;
          if (onSave == null) {
            return _error('onSave 콜백이 필요합니다');
          }
          return _page(OverspendingRuleEditScreen(
            rule: args?['rule'] as Map<String, dynamic>?,
            onSave: onSave,
          ));

        default:
          return _error('페이지를 찾을 수 없습니다');
      }
    } catch (e, stackTrace) {
      // 라우트 생성 중 에러 발생 시 로그 출력
      LoggerService.error(
        'Routing',
        '라우트 생성 실패: ${settings.name}',
        e,
        stackTrace,
      );
      return _error('페이지를 불러올 수 없습니다: $e');
    }
  }
}