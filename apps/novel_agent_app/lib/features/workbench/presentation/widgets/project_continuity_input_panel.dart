import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class ProjectContinuityInputPanel extends StatefulWidget {
  const ProjectContinuityInputPanel({
    super.key,
    required this.input,
    required this.onChanged,
    this.compact = false,
  });

  final ProjectContinuityInputProfile input;
  final ValueChanged<ProjectContinuityInputProfile> onChanged;
  final bool compact;

  @override
  State<ProjectContinuityInputPanel> createState() =>
      _ProjectContinuityInputPanelState();
}

class _ProjectContinuityInputPanelState
    extends State<ProjectContinuityInputPanel> {
  late ProjectContinuityInputProfile _input;
  late final TextEditingController _worldLabelsController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _input = widget.input;
    _worldLabelsController = TextEditingController(
      text: _input.worldLabels.join(' / '),
    );
    _notesController = TextEditingController(text: _input.notes);
  }

  @override
  void didUpdateWidget(covariant ProjectContinuityInputPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input == widget.input) {
      return;
    }
    _input = widget.input;
    if (_worldLabelsController.text != widget.input.worldLabels.join(' / ')) {
      _worldLabelsController.text = widget.input.worldLabels.join(' / ');
    }
    if (_notesController.text != widget.input.notes) {
      _notesController.text = widget.input.notes;
    }
  }

  @override
  void dispose() {
    _worldLabelsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _CompactContinuitySummary(input: _input);
    }
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '剧情机制与连续性',
          style: TextStyle(
            color: colors.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '如果项目存在多世界、多路线、回档，或局部身份覆盖，先在这里声明。更细的作用域和连续性编辑会在项目内继续补充。',
          style: TextStyle(
            color: colors.mutedTextColor,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        _BooleanToggleRow(
          label: '包含多世界/多舞台切换',
          value: _input.usesMultipleWorlds,
          onChanged: (value) => _updateInput(usesMultipleWorlds: value),
        ),
        _BooleanToggleRow(
          label: '包含多路线/支线分叉',
          value: _input.usesBranchingRoutes,
          onChanged: (value) => _updateInput(usesBranchingRoutes: value),
        ),
        _BooleanToggleRow(
          label: '包含回档/回归/重跑机制',
          value: _input.usesReplayResets,
          onChanged: (value) => _updateInput(usesReplayResets: value),
        ),
        _BooleanToggleRow(
          label: '需要局部身份覆盖',
          value: _input.requiresScopedIdentityOverlays,
          onChanged: (value) =>
              _updateInput(requiresScopedIdentityOverlays: value),
        ),
        if (_input.usesMultipleWorlds) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _worldLabelsController,
            decoration: const InputDecoration(
              labelText: '世界/舞台标签',
              hintText: '例如：主世界 / 副本A / 梦境线',
            ),
            onChanged: (value) =>
                _updateInput(worldLabels: _worldLabelsOf(value)),
          ),
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          minLines: 2,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '补充说明',
            hintText: '例如：主角保留记忆，其余角色大多不保留。',
          ),
          onChanged: (value) => _updateInput(notes: value.trim()),
        ),
      ],
    );
  }

  void _updateInput({
    bool? usesMultipleWorlds,
    bool? usesBranchingRoutes,
    bool? usesReplayResets,
    bool? requiresScopedIdentityOverlays,
    List<String>? worldLabels,
    String? notes,
  }) {
    final next = ProjectContinuityInputProfile(
      displayName: _input.displayName,
      usesMultipleWorlds: usesMultipleWorlds ?? _input.usesMultipleWorlds,
      usesBranchingRoutes: usesBranchingRoutes ?? _input.usesBranchingRoutes,
      usesReplayResets: usesReplayResets ?? _input.usesReplayResets,
      requiresScopedIdentityOverlays:
          requiresScopedIdentityOverlays ??
          _input.requiresScopedIdentityOverlays,
      worldLabels: worldLabels ?? _input.worldLabels,
      identityModeOverride: _input.identityModeOverride,
      memoryModeOverride: _input.memoryModeOverride,
      stateModeOverride: _input.stateModeOverride,
      causalModeOverride: _input.causalModeOverride,
      branchModeOverride: _input.branchModeOverride,
      visibilityModeOverride: _input.visibilityModeOverride,
      notes: notes ?? _input.notes,
      metadata: _input.metadata,
    );
    setState(() {
      _input = next;
    });
    widget.onChanged(next);
  }

  List<String> _worldLabelsOf(String raw) {
    return raw
        .split(RegExp(r'[\/,，\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class _BooleanToggleRow extends StatelessWidget {
  const _BooleanToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: colors.textColor, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactContinuitySummary extends StatelessWidget {
  const _CompactContinuitySummary({required this.input});

  final ProjectContinuityInputProfile input;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final tokens = <String>[
      if (input.usesMultipleWorlds) '多世界',
      if (input.usesBranchingRoutes) '多路线',
      if (input.usesReplayResets) '回档/回归',
      if (input.requiresScopedIdentityOverlays) '身份覆盖',
      if (!input.usesMultipleWorlds &&
          !input.usesBranchingRoutes &&
          !input.usesReplayResets &&
          !input.requiresScopedIdentityOverlays)
        '默认单线连续',
    ];
    final details = <String>[
      if (input.worldLabels.isNotEmpty) '世界：${input.worldLabels.join(' / ')}',
      if (input.notes.trim().isNotEmpty) input.notes.trim(),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(border: Border.all(color: colors.lineColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '连续性偏好',
            style: TextStyle(
              color: colors.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tokens.join(' · '),
            style: TextStyle(color: colors.mutedTextColor, fontSize: 12),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...details.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  item,
                  style: TextStyle(
                    color: colors.mutedTextColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
