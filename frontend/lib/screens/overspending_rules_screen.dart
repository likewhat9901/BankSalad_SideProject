import 'package:flutter/material.dart';
import '../services/api/analysis_api.dart';
import '../services/logger_service.dart';

class OverspendingRulesScreen extends StatefulWidget {
  const OverspendingRulesScreen({super.key});

  @override
  State<OverspendingRulesScreen> createState() => _OverspendingRulesScreenState();
}

class _OverspendingRulesScreenState extends State<OverspendingRulesScreen> {
  List<Map<String, dynamic>> _rules = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rules = await AnalysisApi.getOverspendingRules();
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('규칙 로드 실패', e);
      setState(() {
        _errorMessage = '규칙을 불러올 수 없습니다';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRuleEnabled(int ruleId, bool enabled) async {
    try {
      final rule = _rules.firstWhere((r) => r['id'] == ruleId);
      rule['enabled'] = !enabled;
      
      await AnalysisApi.updateOverspendingRule(ruleId, rule);
      
      setState(() {
        final index = _rules.indexWhere((r) => r['id'] == ruleId);
        if (index != -1) {
          _rules[index] = rule;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(enabled ? '규칙이 비활성화되었습니다' : '규칙이 활성화되었습니다')),
        );
      }
    } catch (e) {
      LoggerService.error('규칙 토글 실패', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('규칙 상태 변경에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _deleteRule(int ruleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('규칙 삭제'),
        content: const Text('이 규칙을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AnalysisApi.deleteOverspendingRule(ruleId);
      setState(() {
        _rules.removeWhere((r) => r['id'] == ruleId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('규칙이 삭제되었습니다')),
        );
      }
    } catch (e) {
      LoggerService.error('규칙 삭제 실패', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('규칙 삭제에 실패했습니다')),
        );
      }
    }
  }

  void _showAddRuleDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OverspendingRuleEditScreen(
          onSave: (rule) async {
            try {
              final newRule = await AnalysisApi.createOverspendingRule(rule);
              setState(() {
                _rules.add(newRule);
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('규칙이 추가되었습니다')),
                );
              }
            } catch (e) {
              LoggerService.error('규칙 추가 실패', e);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('규칙 추가에 실패했습니다')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OverspendingRuleEditScreen(
          rule: rule,
          onSave: (updatedRule) async {
            try {
              final savedRule = await AnalysisApi.updateOverspendingRule(
                rule['id'] as int,
                updatedRule,
              );
              setState(() {
                final index = _rules.indexWhere((r) => r['id'] == rule['id']);
                if (index != -1) {
                  _rules[index] = savedRule;
                }
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('규칙이 수정되었습니다')),
                );
              }
            } catch (e) {
              LoggerService.error('규칙 수정 실패', e);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('규칙 수정에 실패했습니다')),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과소비 규칙 관리'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRuleDialog,
            tooltip: '규칙 추가',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRules,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRules,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '규칙이 없습니다',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddRuleDialog,
              icon: const Icon(Icons.add),
              label: const Text('규칙 추가'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRules,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return _buildRuleCard(rule);
        },
      ),
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule) {
    final enabled = rule['enabled'] as bool? ?? true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          enabled ? Icons.check_circle : Icons.cancel,
          color: enabled ? Colors.green : Colors.grey,
        ),
        title: Text(
          rule['name'] as String? ?? '이름 없음',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: enabled ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('카테고리: ${rule['category_filter'] ?? '없음'}'),
            if (rule['per_transaction'] != null)
              Text('건당: ${_formatCurrency(rule['per_transaction'] as int)}'),
            if (rule['weekly_count'] != null)
              Text('주별 횟수: ${rule['weekly_count']}회'),
            if (rule['monthly_count'] != null)
              Text('월별 횟수: ${rule['monthly_count']}회'),
            if (rule['monthly_total'] != null)
              Text('월별 총액: ${_formatCurrency(rule['monthly_total'] as int)}'),
            if (rule['time_filter'] != null)
              Text('시간대: ${rule['time_filter'][0]}시 ~ ${rule['time_filter'][1]}시'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: enabled,
              onChanged: (value) => _toggleRuleEnabled(rule['id'] as int, enabled),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditRuleDialog(rule);
                } else if (value == 'delete') {
                  _deleteRule(rule['id'] as int);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }
}

// 규칙 편집 화면
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
  late TextEditingController _categoryController;
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
    final rule = widget.rule;
    _nameController = TextEditingController(text: rule?['name'] ?? '');
    _categoryController = TextEditingController(text: rule?['category_filter'] ?? '');
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
    _categoryController.dispose();
    _perTransactionController.dispose();
    _weeklyCountController.dispose();
    _monthlyCountController.dispose();
    _monthlyTotalController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rule = <String, dynamic>{
      'name': _nameController.text,
      'category_filter': _categoryController.text,
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '규칙 이름 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? '규칙 이름을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: '카테고리 필터 *',
                border: OutlineInputBorder(),
                hintText: '예: 식사, 카페/간식',
              ),
              validator: (value) => value?.isEmpty ?? true ? '카테고리를 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _perTransactionController,
              decoration: const InputDecoration(
                labelText: '건당 금액 (원)',
                border: OutlineInputBorder(),
                hintText: '예: 10000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weeklyCountController,
              decoration: const InputDecoration(
                labelText: '주별 횟수',
                border: OutlineInputBorder(),
                hintText: '예: 5',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyCountController,
              decoration: const InputDecoration(
                labelText: '월별 횟수',
                border: OutlineInputBorder(),
                hintText: '예: 10',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _monthlyTotalController,
              decoration: const InputDecoration(
                labelText: '월별 총액 (원)',
                border: OutlineInputBorder(),
                hintText: '예: 100000',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
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
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('활성화'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}