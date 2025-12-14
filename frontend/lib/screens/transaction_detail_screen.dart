import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/api/transaction_api.dart';
import '../utils/category_icons.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onUpdate;  // 수정 후 콜백

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.onUpdate,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _paymentMethodController;
  late String _selectedCategory;
  
  bool _isLoading = false;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'ko_KR');

  List<String> get _categories => CategoryIcons.icons.keys.toList();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(text: widget.transaction.amount.abs().toString());
    _paymentMethodController = TextEditingController(text: widget.transaction.paymentMethod);
    _selectedCategory = widget.transaction.category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (widget.transaction.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래내역 ID가 없어 수정할 수 없습니다')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = int.tryParse(_amountController.text);
      if (amount == null) {
        throw Exception('금액을 올바르게 입력해주세요');
      }

      // 원래 금액이 음수였으면 음수로 유지
      final finalAmount = widget.transaction.amount < 0 ? -amount : amount;

      await TransactionApi.updateTransaction(
        transactionId: widget.transaction.id!,
        description: _descriptionController.text,
        amount: finalAmount,
        category: _selectedCategory,
        paymentMethod: _paymentMethodController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래내역이 수정되었습니다')),
        );
        
        // 콜백 실행하여 리스트 화면 업데이트
        widget.onUpdate?.call();
        
        Navigator.of(context).pop(true);  // true 반환하여 수정됨을 알림
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = CategoryIcons.getIcon(_selectedCategory);
    final isExpense = widget.transaction.amount < 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래내역 상세'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 거래일시 (읽기 전용)
            _buildReadOnlyField('거래일시', widget.transaction.date),
            const SizedBox(height: 16),

            // 내용
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 금액
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '금액',
                border: const OutlineInputBorder(),
                suffixText: '원',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // 카테고리
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      Icon(
                        CategoryIcons.getIcon(category)['icon'],
                        color: CategoryIcons.getIcon(category)['color'],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // 결제수단
            TextField(
              controller: _paymentMethodController,
              decoration: const InputDecoration(
                labelText: '결제수단',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 현재 금액 표시
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('현재 금액:', style: TextStyle(fontSize: 16)),
                  Text(
                    '${isExpense ? "-" : "+"}${_currencyFormat.format(widget.transaction.amount.abs())}원',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpense ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}