import 'package:flutter/material.dart';
import '../../transaction/utils/category_icons.dart';

class OverspendingRuleEditScreen extends StatefulWidget {
  final Map<String, dynamic>? rule;
  final Function(Map<String, dynamic>) onSave;

  const OverspendingRuleEditScreen({
    super.key,
    this.rule,
    required this.onSave,
  });

  @override
  State<OverspendingRuleEditScreen> createState() => _OverspendingRuleEditScreenState();
}

class _OverspendingRuleEditScreenState extends State<OverspendingRuleEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedCategory;  
  late TextEditingController _perTransactionController;
  late TextEditingController _weeklyCountController;
  late TextEditingController _monthlyCountController;
  late TextEditingController _monthlyTotalController;
  late TextEditingController _timeStartController;
  late TextEditingController _timeEndController;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final rule = widget.rule;
    _nameController = TextEditingController(text: rule?['name'] ?? '');
    _selectedCategory = rule?['category_filter'] ?? '';
    _perTransactionController = TextEditingController(text: rule?['per_transaction']?.toString() ?? '');
    _weeklyCountController = TextEditingController(text: rule?['weekly_count']?.toString() ?? '');
    _monthlyCountController = TextEditingController(text: rule?['monthly_count']?.toString() ?? '');
    _monthlyTotalController = TextEditingController(text: rule?['monthly_total']?.toString() ?? '');
    _timeStartController = TextEditingController(text: rule?['time_filter']?[0]?.toString() ?? '');
    _timeEndController = TextEditingController(text: rule?['time_filter']?[1]?.toString() ?? '');
    _enabled = rule?['enabled'] ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _perTransactionController.dispose();
    _weeklyCountController.dispose();
    _monthlyCountController.dispose();
    _monthlyTotalController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? '규칙 추가' : '규칙 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildPerTransactionField(),
            const SizedBox(height: 16),
            _buildWeeklyCountField(),
            const SizedBox(height: 16),
            _buildMonthlyCountField(),
            const SizedBox(height: 16),
            _buildMonthlyTotalField(),
            const SizedBox(height: 16),
            _buildTimeFields(),
            const SizedBox(height: 16),
            _buildEnabledSwitch(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // 빌드 헬퍼 메서드들
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '규칙 이름 *',
        border: OutlineInputBorder(),
      ),
      validator: (value) => value?.isEmpty ?? true ? '규칙 이름을 입력하세요' : null,
    );
  }

  Widget _buildCategoryField() {
    final categories = CategoryIcons.icons.keys.toList()..sort();
    
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: '카테고리 필터 *',
        border: OutlineInputBorder(),
      ),
      items: categories.map((category) {
        final iconData = CategoryIcons.getIcon(category)['icon'] as IconData;
        final color = CategoryIcons.getIcon(category)['color'] as Color;
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(iconData, color: color, size: 20),
              const SizedBox(width: 8),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) => value == null ? '카테고리를 선택하세요' : null,
    );
  }

  Widget _buildPerTransactionField() {
    return TextFormField(
      controller: _perTransactionController,
      decoration: const InputDecoration(
        labelText: '건당 금액 (원)',
        border: OutlineInputBorder(),
        hintText: '예: 10000',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildWeeklyCountField() {
    return TextFormField(
      controller: _weeklyCountController,
      decoration: const InputDecoration(
        labelText: '주별 횟수',
        border: OutlineInputBorder(),
        hintText: '예: 5',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMonthlyCountField() {
    return TextFormField(
      controller: _monthlyCountController,
      decoration: const InputDecoration(
        labelText: '월별 횟수',
        border: OutlineInputBorder(),
        hintText: '예: 10',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildMonthlyTotalField() {
    return TextFormField(
      controller: _monthlyTotalController,
      decoration: const InputDecoration(
        labelText: '월별 총액 (원)',
        border: OutlineInputBorder(),
        hintText: '예: 100000',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildTimeFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _timeStartController,
            decoration: const InputDecoration(
              labelText: '시작 시간 (시)',
              border: OutlineInputBorder(),
              hintText: '예: 18',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _timeEndController,
            decoration: const InputDecoration(
              labelText: '종료 시간 (시)',
              border: OutlineInputBorder(),
              hintText: '예: 6',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledSwitch() {
    return SwitchListTile(
      title: const Text('활성화'),
      value: _enabled,
      onChanged: (value) => setState(() => _enabled = value),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('저장'),
    );
  }

  // 비즈니스 로직
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rule = <String, dynamic>{
      'name': _nameController.text,
      'category_filter': _selectedCategory,
      'enabled': _enabled,
    };

    if (widget.rule != null) {
      rule['id'] = widget.rule!['id'];
    }

    if (_perTransactionController.text.isNotEmpty) {
      rule['per_transaction'] = int.tryParse(_perTransactionController.text);
    }
    if (_weeklyCountController.text.isNotEmpty) {
      rule['weekly_count'] = int.tryParse(_weeklyCountController.text);
    }
    if (_monthlyCountController.text.isNotEmpty) {
      rule['monthly_count'] = int.tryParse(_monthlyCountController.text);
    }
    if (_monthlyTotalController.text.isNotEmpty) {
      rule['monthly_total'] = int.tryParse(_monthlyTotalController.text);
    }
    if (_timeStartController.text.isNotEmpty && _timeEndController.text.isNotEmpty) {
      rule['time_filter'] = [
        int.tryParse(_timeStartController.text) ?? 0,
        int.tryParse(_timeEndController.text) ?? 0,
      ];
    }

    widget.onSave(rule);
  }
}