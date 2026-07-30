import 'package:flutter/material.dart';

import '../../../../shared/widgets/confirmation_dialog.dart';
import '../models/project_assets_view_data.dart';

class ExpressionConstraintBindingEditorPanel extends StatefulWidget {
  const ExpressionConstraintBindingEditorPanel({
    super.key,
    required this.viewData,
    required this.onSaveRequested,
    required this.onRemoveRequested,
  });

  final ExpressionConstraintBindingEditorViewData viewData;
  final ValueChanged<ExpressionConstraintBindingEditorRequestViewData>
  onSaveRequested;
  final ValueChanged<String> onRemoveRequested;

  @override
  State<ExpressionConstraintBindingEditorPanel> createState() =>
      _ExpressionConstraintBindingEditorPanelState();
}

class _ExpressionConstraintBindingEditorPanelState
    extends State<ExpressionConstraintBindingEditorPanel> {
  late final TextEditingController _weightController;
  late bool _enabled;
  late bool _defaultForProject;
  late String _selectedPolicyMode;
  late Set<String> _selectedAgentIds;
  late Set<String> _selectedModeIds;
  late Set<String> _selectedStageIds;

  @override
  void initState() {
    // 中文注释: 面板内部先持有本地草稿，避免用户修改一个字段就立即反向污染外层视图态。
    super.initState();
    _weightController = TextEditingController();
    _apply(widget.viewData);
  }

  @override
  void didUpdateWidget(
    covariant ExpressionConstraintBindingEditorPanel oldWidget,
  ) {
    // 中文注释: 当用户切换规则方案或外层刷新保存结果时，编辑器需要整体替换成本轮草稿。
    super.didUpdateWidget(oldWidget);
    if (_viewSignature(oldWidget.viewData) != _viewSignature(widget.viewData)) {
      final oldProfileId = oldWidget.viewData.profileId;
      // 切换规则方案前，若当前 binding 有未保存修改，先落盘旧方案，避免被 _apply 静默覆盖丢失。
      if (oldProfileId != widget.viewData.profileId &&
          oldProfileId.trim().isNotEmpty &&
          _isDirtyAgainst(oldWidget.viewData)) {
        final pending = _buildSaveRequest(profileId: oldProfileId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onSaveRequested(pending);
          }
        });
      }
      _apply(widget.viewData);
    }
  }

  @override
  void dispose() {
    // 中文注释: 表单控制器只属于当前面板实例，页面切换时及时释放，避免旧草稿残留。
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 这个面板只承担“查看规则方案 + 编辑项目级 binding”，不承担方案本体编辑职责。
    if (widget.viewData.profileId.trim().isEmpty) {
      final entryAgentContextId = widget.viewData.entryAgentContextId.trim();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('当前没有可编辑的表达限制方案。'),
              if (entryAgentContextId.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '当前入口智能体：$entryAgentContextId',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      );
    }
    final entryAgentContextId = widget.viewData.entryAgentContextId.trim();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          '表达限制',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          entryAgentContextId.isEmpty
              ? '表达限制是项目级写作约束系统，可为整个项目或特定智能体挂载写作规则方案。'
              : '表达限制是项目级写作约束系统；当前正从智能体 $entryAgentContextId 进入，可继续为它定向绑定写作规则方案。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          widget.viewData.displayName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(widget.viewData.kindLabel),
            _chip(widget.viewData.originLabel),
            _chip(_bindingStateLabel),
          ],
        ),
        if (widget.viewData.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(widget.viewData.summary),
        ],
        const SizedBox(height: 16),
        _overviewCard(context),
        const SizedBox(height: 16),
        _policySelectorSection(context),
        const SizedBox(height: 16),
        _projectBindingSection(context),
        const SizedBox(height: 20),
        _section(
          context,
          title: '写作规则',
          items: widget.viewData.rules,
          emptyText: '当前规则方案没有提供额外写作规则。',
        ),
        const SizedBox(height: 16),
        _section(
          context,
          title: '风险信号',
          items: widget.viewData.riskSignals,
          emptyText: '当前规则方案没有列出风险信号。',
        ),
        const SizedBox(height: 16),
        _advancedSection(context),
      ],
    );
  }

  Widget _overviewCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(
              context,
              label: '使用策略',
              value: _policyOptionLabel(_selectedPolicyMode),
              detail: widget.viewData.usageStrategySummary,
            ),
            const Divider(height: 20),
            _summaryRow(
              context,
              label: '强度',
              value: widget.viewData.strengthSummary,
            ),
            const Divider(height: 20),
            _summaryRow(
              context,
              label: '适用范围',
              value: widget.viewData.scopeSummary,
            ),
            const Divider(height: 20),
            _summaryRow(
              context,
              label: '写作规则',
              value: widget.viewData.rules.isEmpty
                  ? '当前没有额外规则。'
                  : '共 ${widget.viewData.rules.length} 条，见下方“写作规则”。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required String value,
    String detail = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
        if (detail.trim().isNotEmpty && detail.trim() != value.trim()) ...[
          const SizedBox(height: 4),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }

  Widget _policySelectorSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('使用策略', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '按当前项目选择表达规则的使用强度；关闭只停用表达规则，不会自动删掉这条项目绑定。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selectedPolicyMode,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedPolicyMode = value);
              },
              child: Column(
                children: [
                  for (final option in widget.viewData.availablePolicyOptions)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: option.id,
                      title: Text(option.label),
                      subtitle: Text(option.description),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _projectBindingSection(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('项目设置', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('纳入当前项目'),
              subtitle: const Text('关闭后会保留这套规则方案，但当前项目暂不参与解析。'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('设为项目默认'),
              subtitle: const Text('未指定智能体、模式或阶段时，按默认方案参与解析。'),
              value: _defaultForProject,
              onChanged: (value) => setState(() => _defaultForProject = value),
            ),
            _agentSelectorSection(context),
            _modeSelectorSection(context),
            _stageSelectorSection(context),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _submit, child: const Text('保存设置')),
                OutlinedButton(
                  onPressed: widget.viewData.hasBinding
                      ? () async {
                          // 中文注释: 移除绑定会改写项目绑定文件、即时落盘且无撤销——
                          // 与同表面的风格/伏笔删除对称，二次确认。
                          final confirmed = await showConfirmationDialog(
                            context,
                            title: '移除该表达限制绑定？',
                            message: '移除后该项目将不再装载此表达限制方案，需重新绑定才能恢复。',
                            confirmLabel: '移除',
                          );
                          if (confirmed) {
                            widget.onRemoveRequested(widget.viewData.profileId);
                          }
                        }
                      : null,
                  child: const Text('移除绑定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    // 中文注释: 辅助标签统一收成小方法，避免标题区域散落重复的 Chip 配置。
    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    // 中文注释: 高级区继续保留轻量输入字段，避免把权重一类次级设置塞进主面板。
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _agentSelectorSection(BuildContext context) {
    final options = widget.viewData.availableAgentOptions;
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '当前项目里还没有可选智能体。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('定向智能体', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            '直接从当前项目智能体中选择，不再手填内部标识。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final option in options)
            CheckboxListTile(
              value: _selectedAgentIds.contains(option.id),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(option.label),
              subtitle: option.note.trim().isEmpty ? null : Text(option.note),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedAgentIds.add(option.id);
                  } else {
                    _selectedAgentIds.remove(option.id);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _modeSelectorSection(BuildContext context) {
    final options = widget.viewData.availableModeOptions;
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '当前没有可选写作模式。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('定向模式', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('直接从已知写作模式中选择。', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final option in options)
            CheckboxListTile(
              value: _selectedModeIds.contains(option.id),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(option.label),
              subtitle: option.note.trim().isEmpty ? null : Text(option.note),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedModeIds.add(option.id);
                  } else {
                    _selectedModeIds.remove(option.id);
                    _selectedStageIds.removeWhere(
                      (stageId) => !_visibleStageIds.contains(stageId),
                    );
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _stageSelectorSection(BuildContext context) {
    final options = _visibleStageOptions;
    if (widget.viewData.availableStageOptions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text('当前没有可选阶段。', style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('定向阶段', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            _selectedModeIds.isEmpty
                ? '先选择模式可缩小阶段范围；当前展示全部已知阶段。'
                : '阶段会跟随已选模式过滤。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final option in options)
            CheckboxListTile(
              value: _selectedStageIds.contains(option.id),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(option.label),
              subtitle: option.note.trim().isEmpty ? null : Text(option.note),
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedStageIds.add(option.id);
                  } else {
                    _selectedStageIds.remove(option.id);
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String emptyText,
  }) {
    // 中文注释: 规则与风险信号目前只读展示，统一用同一段渲染逻辑保持面板轻量。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $item'),
            ),
      ],
    );
  }

  Widget _advancedSection(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: const Text('高级与诊断'),
      subtitle: const Text('这里保留内部标识、注入方式和次级设置。'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_weightController, '优先级权重'),
              for (final field in widget.viewData.diagnosticFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        field.value.trim().isEmpty ? '未设置' : field.value,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _apply(ExpressionConstraintBindingEditorViewData viewData) {
    // 中文注释: 选中项变化时统一刷新本地表单草稿，避免每个字段各自判断同步条件。
    _enabled = viewData.enabled;
    _defaultForProject = viewData.defaultForProject;
    _selectedPolicyMode = viewData.selectedPolicyMode;
    _selectedAgentIds = Set<String>.from(viewData.selectedAgentIds);
    _selectedModeIds = Set<String>.from(viewData.selectedModeIds);
    _selectedStageIds = Set<String>.from(viewData.selectedStageIds);
    _weightController.text = viewData.weightText;
  }

  void _submit() {
    // 中文注释: 提交时只把编辑器关心的 binding 字段回传出去，保存与写盘继续留给控制器和工作区服务。
    widget.onSaveRequested(
      _buildSaveRequest(profileId: widget.viewData.profileId),
    );
  }

  /// 当前 binding 是否有别于 [viewData]（即存在未保存的修改）。
  bool _isDirtyAgainst(ExpressionConstraintBindingEditorViewData viewData) {
    if (_enabled != viewData.enabled) return true;
    if (_defaultForProject != viewData.defaultForProject) return true;
    if (_selectedPolicyMode != viewData.selectedPolicyMode) return true;
    if (!_setEquals(_selectedAgentIds, viewData.selectedAgentIds)) return true;
    if (!_setEquals(_selectedModeIds, viewData.selectedModeIds)) return true;
    if (!_setEquals(_selectedStageIds, viewData.selectedStageIds)) return true;
    if (_weightController.text != viewData.weightText) return true;
    return false;
  }

  ExpressionConstraintBindingEditorRequestViewData _buildSaveRequest({
    required String profileId,
  }) {
    return ExpressionConstraintBindingEditorRequestViewData(
      profileId: profileId,
      selectedPolicyMode: _selectedPolicyMode,
      enabled: _enabled,
      defaultForProject: _defaultForProject,
      selectedAgentIds: _selectedAgentIds.toList(growable: false),
      selectedModeIds: _selectedModeIds.toList(growable: false),
      selectedStageIds: _selectedStageIds.toList(growable: false),
      targetAgentIdsText: _selectedAgentIds.join(', '),
      targetModeIdsText: _selectedModeIds.join(', '),
      targetStageIdsText: _selectedStageIds.join(', '),
      weightText: _weightController.text,
    );
  }

  bool _setEquals(Set<String> a, Iterable<String> b) {
    final other = b.toSet();
    return a.length == other.length && a.containsAll(other);
  }

  List<ExpressionConstraintSelectableOptionViewData> get _visibleStageOptions {
    if (_selectedModeIds.isEmpty) {
      return widget.viewData.availableStageOptions;
    }
    return widget.viewData.availableStageOptions
        .where((option) {
          return _selectedModeIds.contains(option.groupId);
        })
        .toList(growable: false);
  }

  Set<String> get _visibleStageIds {
    return _visibleStageOptions.map((item) => item.id).toSet();
  }

  String get _bindingStateLabel {
    if (!_enabled) {
      return '当前停用';
    }
    return widget.viewData.hasBinding ? '已纳入项目' : '尚未纳入项目';
  }

  String _policyOptionLabel(String policyMode) {
    for (final option in widget.viewData.availablePolicyOptions) {
      if (option.id == policyMode) {
        return option.label;
      }
    }
    return '智能使用';
  }

  String _viewSignature(ExpressionConstraintBindingEditorViewData viewData) {
    return <String>[
      viewData.profileId,
      viewData.bindingId,
      viewData.selectedPolicyMode,
      '${viewData.enabled}',
      '${viewData.defaultForProject}',
      viewData.weightText,
      viewData.selectedAgentIds.join('|'),
      viewData.selectedModeIds.join('|'),
      viewData.selectedStageIds.join('|'),
    ].join('::');
  }
}
