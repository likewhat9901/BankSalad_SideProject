import '../../models/transaction.dart';
import 'base_api_client.dart';

class TransactionApi {
  /// 거래내역 조회 (페이지네이션)
  static Future<Map<String, dynamic>> getTransactionsPaginated({
    int limit = 50,  // 한 번에 가져올 거래내역 개수 (기본값: 50)
    int offset = 0,  // 건너뛸 거래내역 개수 (페이지네이션용, 기본값: 0)
    String? category,  // 카테고리 필터 (선택사항)
    String? startDate,  // 시작 날짜 필터 (선택사항, 형식: "YYYY-MM-DD")
    String? endDate,  // 종료 날짜 필터 (선택사항, 형식: "YYYY-MM-DD")
  }) async {
    // 쿼리 파라미터 맵 생성 (필수 파라미터)
    final queryParams = <String, String>{
      'limit': limit.toString(),  // 숫자를 문자열로 변환
      'offset': offset.toString(),  // 숫자를 문자열로 변환
    };
    // 선택적 파라미터 추가 (null이 아닐 때만)
    if (category != null) queryParams['category'] = category;  // 카테고리 필터 추가
    if (startDate != null) queryParams['start_date'] = startDate;  // 시작 날짜 필터 추가
    if (endDate != null) queryParams['end_date'] = endDate;  // 종료 날짜 필터 추가

    final data = await BaseApiClient.get(
      '/transactions/',
      queryParams: queryParams,
      logMessage: '거래내역 조회 API 요청',
    );

    // 데이터 변환
    final List<dynamic> txList = data['transactions'] ?? [];
    final List<Transaction> transactions =
        txList.map((json) => Transaction.fromJson(json)).toList();

    return {
      'transactions': transactions,
      'total_count': (data['total_count'] ?? 0).toInt(),
      'has_more': (data['has_more'] ?? false),
    };
  }

  /// 거래내역 수정
  static Future<Map<String, dynamic>> updateTransaction({
    required String transactionId,  // 필수: 거래내역 ID
    String? description,            // 선택사항: 거래내역 내용
    int? amount,                    // 선택사항: 금액 (음수: 지출, 양수: 수입)
    String? category,               // 선택사항: 대분류
    String? paymentMethod,          // 선택사항: 결제수단
  }) async {
    // transactionId를 int로 변환
    final id = int.tryParse(transactionId);   // 문자열을 정수로 변환 시도
    if (id == null) {  // 변환 실패 시
      throw Exception('유효하지 않은 거래내역 ID입니다');  // 예외 던짐
    }

    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (amount != null) body['amount'] = amount;
    if (category != null) body['category'] = category;
    if (paymentMethod != null) body['payment_method'] = paymentMethod;

    return await BaseApiClient.put(
      '/transactions/$id',
      body,
      logMessage: '거래내역 수정 API 요청',
    );
  }
}