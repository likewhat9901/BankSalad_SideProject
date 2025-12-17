class Transaction {
  final String? id;     // 수정을 위한 고유 식별자
  final String date;
  final String description;
  final int amount;
  final String category;
  final String paymentMethod;

  Transaction({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString(),
      date: json['거래일시'] ?? '',
      description: json['내용'] ?? '',
      amount: (json['금액'] ?? json['출금액'] ?? 0).toInt(),
      category: json['대분류'] ?? '기타',
      paymentMethod: json['결제수단'] ?? '기타',
    );
  }

  // JSON 변환 메서드 (수정 시 사용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      '거래일시': date,
      '내용': description,
      '금액': amount,
      '대분류': category,
      '결제수단': paymentMethod,
    };
  }

  // 복사 생성자 (수정 시 사용)
  Transaction copyWith({
    String? id,
    String? date,
    String? description,
    int? amount,
    String? category,
    String? paymentMethod,
  }) {
    return Transaction(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}