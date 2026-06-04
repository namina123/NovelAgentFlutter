import 'package:flutter/material.dart';

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
    // 中文注释: 当用户切换到另一个 preset 时，编辑器需要整体替换成本轮选中的绑定草稿。
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.profileId != widget.viewData.profileId ||
        oldWidget.viewData.sourcePath != widget.viewData.sourcePath ||
        oldWidget.viewData.hasBinding != widget.viewData.hasBinding) {
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
    // 中文注释: 这个面板只承担“查看 preset + 编辑项目级 binding”，不承担 preset 本体编辑职责。
    if (widget.viewData.profileId.trim().isEmpty) {
      final entryAgentContextId = widget.viewData.entryAgentContextId.trim();
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('当前没有可编辑的表达限制 preset。'),
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
    final isBuiltin = widget.viewData.isBuiltin;
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
              ? '表达限制是项目级写作约束系统，可为整个项目或特定智能体挂载写作约束预设。'
              : '表达限制是项目级写作约束系统；当前正从智能体 $entryAgentContextId 进入，可继续为它定向绑定写作约束预设。',
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
            _chip(isBuiltin ? '内置预设' : '项目预设'),
            _chip(widget.viewData.hasBinding ? '已配置绑定' : '尚未绑定'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '当前预设 ID：${widget.viewData.profileId}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (isBuiltin) ...[
          const SizedBox(height: 6),
          Text(
            '这是表达限制系统中的一个内置预设，不是系统总名；后续可以继续叠加其他预设。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (widget.viewData.summary.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(widget.viewData.summary),
        ],
        if (widget.viewData.sourcePath.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '来源：${widget.viewData.sourcePath}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (widget.viewData.recommendedScopeText.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '推荐作用域：${widget.viewData.recommendedScopeText}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (widget.viewData.entryAgentContextId.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '当前入口智能体：${widget.viewData.entryAgentContextId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        const Text('项目绑定', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('启用这个表达限制预设'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('设为项目默认绑定'),
            subtitle: const Text('未指定 agent / mode / stage 时按默认绑定参与解析。'),
            value: _defaultForProject,
            onChanged: (value) => setState(() => _defaultForProject = value),
          ),
        ),
        _agentSelectorSection(context),
        _modeSelectorSection(context),
        _stageSelectorSection(context),
        _field(_weightController, '权重'),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(onPressed: _submit, child: const Text('保存绑定')),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.viewData.hasBinding
                  ? () => widget.onRemoveRequested(widget.viewData.profileId)
                  : null,
              child: const Text('移除绑定'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _section(
          context,
          title: '规则',
          items: widget.viewData.rules,
          emptyText: '当前 preset 没有提供额外规则。',
        ),
        const SizedBox(height: 16),
        _section(
          context,
          title: '风险信号',
          items: widget.viewData.riskSignals,
          emptyText: '当前 preset 没有列出风险信号。',
        ),
      ],
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
    // 中文注释: 当前最小入口继续使用文本字段承载 scope ids，后续升级选择器时只需替换这里。
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
          '当前项目里没有可选智能体；暂不支持手填 Agent ID。',
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
            '不再手填内部 Agent ID，直接从当前项目智能体中选择。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...options.map(
            (option) => Material(
              color: Colors.transparent,
              child: CheckboxListTile(
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
            ),
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
          Text(
            '直接选择已知写作模式，不再手填内部 Mode ID。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...options.map(
            (option) => Material(
              color: Colors.transparent,
              child: CheckboxListTile(
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
            ),
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
        child: Text(
          '当前没有可选阶段。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
                ? '先选择模式可缩小阶段范围；当前先展示全部已知阶段。'
                : '阶段会跟随已选模式过滤，不再手填内部 Stage ID。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          ...options.map(
            (option) => Material(
              color: Colors.transparent,
              child: CheckboxListTile(
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
            ),
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
    // 中文注释: preset 规则与风险信号目前只读展示，统一用同一段渲染逻辑保持面板轻量。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('- $item'),
            ),
          ),
      ],
    );
  }

  void _apply(ExpressionConstraintBindingEditorViewData viewData) {
    // 中文注释: 选中项变化时统一刷新本地表单草稿，避免每个字段各自判断同步条件。
    _enabled = viewData.enabled;
    _defaultForProject = viewData.defaultForProject;
    _selectedAgentIds = Set<String>.from(viewData.selectedAgentIds);
    _selectedModeIds = Set<String>.from(viewData.selectedModeIds);
    _selectedStageIds = Set<String>.from(viewData.selectedStageIds);
    _weightController.text = viewData.weightText;
  }

  void _submit() {
    // 中文注释: 提交时只把编辑器关心的 binding 字段回传出去，保存与写盘继续留给控制器和工作区服务。
    widget.onSaveRequested(
      ExpressionConstraintBindingEditorRequestViewData(
        profileId: widget.viewData.profileId,
        enabled: _enabled,
        defaultForProject: _defaultForProject,
        selectedAgentIds: _selectedAgentIds.toList(growable: false),
        selectedModeIds: _selectedModeIds.toList(growable: false),
        selectedStageIds: _selectedStageIds.toList(growable: false),
        targetAgentIdsText: _selectedAgentIds.join(', '),
        targetModeIdsText: _selectedModeIds.join(', '),
        targetStageIdsText: _selectedStageIds.join(', '),
        weightText: _weightController.text,
      ),
    );
  }

  List<ExpressionConstraintSelectableOptionViewData> get _visibleStageOptions {
    if (_selectedModeIds.isEmpty) {
      return widget.viewData.availableStageOptions;
    }
    return widget.viewData.availableStageOptions.where((option) {
      return _selectedModeIds.contains(option.groupId);
    }).toList(growable: false);
  }

  Set<String> get _visibleStageIds {
    return _visibleStageOptions.map((item) => item.id).toSet();
  }
}
