import 'app_route.dart';
import '../logger/logger_service.dart';

class PushRouter {
  static void handle(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == null) {
      LoggerService.warning('PushRouter', '푸시 알림 타입이 없습니다: $data');
      return;
    }
    
    switch (type) {
      case 'transaction':
        AppRoutes.pushNamed(
          AppRoutes.transactionDetail,
          arguments: {
            'id': data['id'],
          },
        );
        break;

      default:
        break;
    }
  }
}