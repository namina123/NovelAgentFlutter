import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';
import '../models/project_creation_expression_constraint_defaults_view_data.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';

class ProjectCreationExpressionConstraintDefaultsPanel extends StatefulWidget {
  const ProjectCreationExpressionConstraintDefaultsPanel({
    super.key,
    required this.viewData,
    required this.onSaved,
  });

  final ProjectCreationExpressionConstraintDefaultsViewData viewData;
  final ValueChanged<Map<String, Object?>> onSaved;

  @override
  State<ProjectCreationExpressionConstraintDefaultsPanel> createState() =>
      _ProjectCreationExpressionConstraintDefaultsPanelState();
}

class _ProjectCreationExpressionConstraintDefaultsPanelState
    extends State<ProjectCreationExpressionConstraintDefaultsPanel> {
  late ProjectCreationExpressionConstraintDefaultsMode _mode;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(
    covariant ProjectCreationExpressionConstraintDefaultsPanel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData != widget.viewData) {
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsFormSection(
      title: '项目创建默认表达限制',
      description:
          '这里只决定“新项目创建后，如果项目当前还没有表达限制 binding，要不要自动装载哪些 profile”。不会在这里编辑项目内 binding。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsLabeledDropdownField<String>(
            label: '默认装载策略',
            value: _mode.name,
            options: [
              SettingsDropdownOption(
                value: ProjectCreationExpressionConstraintDefaultsMode
                    .builtinFallback
                    .name,
                label: '沿用内置回落',
              ),
              SettingsDropdownOption(
                value:
                    ProjectCreationExpressionConstraintDefaultsMode.custom.name,
                label: '自定义默认装载',
              ),
              SettingsDropdownOption(
                value: ProjectCreationExpressionConstraintDefaultsMode
                    .disabled
                    .name,
                label: '不自动装载',
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _mode = ProjectCreationExpressionConstraintDefaultsMode.values
                    .firstWhere(
                      (entry) => entry.name == value,
                      orElse: () =>
                          ProjectCreationExpressionConstraintDefaultsMode
                              .builtinFallback,
                    );
              });
            },
          ),
          const SizedBox(height: 12),
          Text(_modeDescription()),
          if (_mode == ProjectCreationExpressionConstraintDefaultsMode.custom)
            ..._buildOptionRows(),
          const SizedBox(height: 16),
          ActionButton(
            label: '保存项目创建默认表达限制',
            expanded: true,
            icon: Icons.save_outlined,
            onPressed: () {
              widget.onSaved(<String, Object?>{
                'mode': _mode.name,
                'profile_ids': _selectedIds.toList(growable: false),
              });
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptionRows() {
    if (widget.viewData.options.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      const SizedBox(height: 14),
      for (final option in widget.viewData.options) ...[
        _ProjectCreationExpressionConstraintOptionRow(
          option: option,
          value: _selectedIds.contains(option.id),
          onChanged: (value) {
            setState(() {
              if (value) {
                _selectedIds.add(option.id);
              } else {
                _selectedIds.remove(option.id);
              }
            });
          },
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  String _modeDescription() {
    switch (_mode) {
      case ProjectCreationExpressionConstraintDefaultsMode.builtinFallback:
        final fallback = widget.viewData.fallbackSummary.trim();
        return fallback.isEmpty
            ? '当前未写入显式配置时，会沿用内置回落。'
            : '当前未写入显式配置时，会沿用内置回落：$fallback。';
      case ProjectCreationExpressionConstraintDefaultsMode.custom:
        return '只有新建项目且项目当前还没有 binding 时，才会按下面勾选的 profile 自动种入。';
      case ProjectCreationExpressionConstraintDefaultsMode.disabled:
        return '新建项目时不自动装载任何表达限制。';
    }
  }

  void _sync() {
    _mode = widget.viewData.mode;
    _selectedIds = widget.viewData.options
        .where((option) => option.isSelected)
        .map((option) => option.id)
        .toSet();
  }
}

class _ProjectCreationExpressionConstraintOptionRow extends StatelessWidget {
  const _ProjectCreationExpressionConstraintOptionRow({
    required this.option,
    required this.value,
    required this.onChanged,
  });

  final ProjectCreationExpressionConstraintOptionViewData option;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: (next) => onChanged(next ?? false)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.isMissing ? '${option.label}（未解析）' : option.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (option.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    option.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
