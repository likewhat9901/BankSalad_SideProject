import 'package:flutter/material.dart';
import '../analysis_api.dart';
import '../../../core/logger/logger_service.dart';
import '../../../core/utils/formatters/currency_formatter.dart';
import '../../../core/routing/app_route.dart';

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

  // 빌드 헬퍼 메서드들
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_rules.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadRules,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          return _buildRuleCard(_rules[index]);
        },
      ),
    );
  }

  Widget _buildErrorView() {
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

  Widget _buildEmptyView() {
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
        subtitle: _buildRuleSubtitle(rule),
        trailing: _buildRuleTrailing(rule, enabled),
      ),
    );
  }

  Widget _buildRuleSubtitle(Map<String, dynamic> rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text('카테고리: ${rule['category_filter'] ?? '없음'}'),
        if (rule['per_transaction'] != null)
          Text('건당: ${CurrencyFormatter.formatWithCurrency(rule['per_transaction'] as int)}'),
        if (rule['weekly_count'] != null)
          Text('주별 횟수: ${rule['weekly_count']}회'),
        if (rule['monthly_count'] != null)
          Text('월별 횟수: ${rule['monthly_count']}회'),
        if (rule['monthly_total'] != null)
          Text('월별 총액: ${CurrencyFormatter.formatWithCurrency(rule['monthly_total'] as int)}'),
        if (rule['time_filter'] != null)
          Text('시간대: ${rule['time_filter'][0]}시 ~ ${rule['time_filter'][1]}시'),
      ],
    );
  }

  Widget _buildRuleTrailing(Map<String, dynamic> rule, bool enabled) {
    return Row(
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
    );
  }

  // 이벤트 핸들러
  void _showAddRuleDialog() {
    Navigator.pushNamed(
      context,
      AppRoutes.overspendingRuleEdit,
      arguments: {
        'onSave': _handleRuleAdded,
      },
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    Navigator.pushNamed(
      context,
      AppRoutes.overspendingRuleEdit,
      arguments: {
        'rule': rule,
        'onSave': (updatedRule) => _handleRuleUpdated(rule, updatedRule),
      },
    );
  }

  // 비즈니스 로직
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
      LoggerService.error('Analysis', '규칙 로드 실패', e);
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
      LoggerService.error('Analysis', '규칙 토글 실패', e);
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
      LoggerService.error('Analysis', '규칙 삭제 실패', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('규칙 삭제에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _handleRuleAdded(Map<String, dynamic> rule) async {
    try {
      final newRule = await AnalysisApi.createOverspendingRule(rule);
      if (!mounted || !context.mounted) return;
      setState(() {
        _rules.add(newRule);
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('규칙이 추가되었습니다')),
      );
    } catch (e) {
      LoggerService.error('Analysis', '규칙 추가 실패', e);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('규칙 추가에 실패했습니다')),
      );
    }
  }

  Future<void> _handleRuleUpdated(Map<String, dynamic> oldRule, Map<String, dynamic> updatedRule) async {
    try {
      final savedRule = await AnalysisApi.updateOverspendingRule(
        oldRule['id'] as int,
        updatedRule,
      );
      setState(() {
        final index = _rules.indexWhere((r) => r['id'] == oldRule['id']);
        if (index != -1) {
          _rules[index] = savedRule;
        }
      });
      if (!mounted || !context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('규칙이 수정되었습니다')),
      );
    } catch (e) {
      LoggerService.error('Analysis', '규칙 수정 실패', e);
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('규칙 수정에 실패했습니다')),
      );
    }
  }
}