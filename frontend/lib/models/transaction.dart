class Transaction {
  final String date;
  final String description;
  final int amount;
  final String category;
  final String paymentMethod;

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.category,
    required this.paymentMethod,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['거래일시'] ?? '',
      description: json['내용'] ?? '',
      amount: (json['금액'] ?? json['출금액'] ?? 0).toInt(),
      category: json['대분류'] ?? '기타',
      paymentMethod: json['결제수단'] ?? '기타',
    );
  }
}