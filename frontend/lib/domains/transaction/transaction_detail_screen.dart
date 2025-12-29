import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction.dart';
import 'transaction_api.dart';
import 'utils/category_icons.dart';

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

  @override
  Widget build(BuildContext context) {
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
            _buildReadOnlyField('거래일시', widget.transaction.date),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildPaymentMethodField(),
            const SizedBox(height: 24),
            _buildCurrentAmountDisplay(),
          ],
        ),
      ),
    );
  }

  // 빌드 헬퍼 메서드들
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

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: '내용',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: '금액',
        border: OutlineInputBorder(),
        suffixText: '원',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildCategoryField() {
    final iconData = CategoryIcons.getIcon(_selectedCategory);
    
    return InkWell(
      onTap: () => _showCategoryPicker(),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '카테고리',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Icon(iconData['icon'], color: iconData['color'], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_selectedCategory)),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final iconData = CategoryIcons.getIcon(category);
            return ListTile(
              leading: Icon(iconData['icon'], color: iconData['color']),
              title: Text(category),
              selected: category == _selectedCategory,
              onTap: () {
                setState(() => _selectedCategory = category);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMethodField() {
    return TextField(
      controller: _paymentMethodController,
      decoration: const InputDecoration(
        labelText: '결제수단',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCurrentAmountDisplay() {
    final isExpense = widget.transaction.amount < 0;
    final amount = widget.transaction.amount.abs();
    
    return Container(
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
            '${isExpense ? "-" : "+"}${_currencyFormat.format(amount)}원',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // 비즈니스 로직
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
        
        widget.onUpdate?.call();
        Navigator.of(context).pop(true);
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
}