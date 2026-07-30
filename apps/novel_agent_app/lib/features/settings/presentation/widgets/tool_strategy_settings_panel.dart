import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/project_creation_expression_constraint_defaults_view_data.dart';
import '../../../workbench/presentation/models/tool_preview_mode.dart';
import 'project_creation_expression_constraint_defaults_panel.dart';
import 'settings_form_section.dart';
import 'settings_labeled_dropdown_field.dart';
import 'settings_switch_row.dart';

class ToolStrategySettingsPanel extends StatefulWidget {
  const ToolStrategySettingsPanel({
    super.key,
    required this.settings,
    required this.onSaved,
    this.projectCreationDefaultsViewData,
    this.onProjectCreationDefaultsSaved,
  });

  final Map<String, Object?> settings;
  final ValueChanged<Map<String, Object?>> onSaved;
  final ProjectCreationExpressionConstraintDefaultsViewData?
  projectCreationDefaultsViewData;
  final ValueChanged<Map<String, Object?>>? onProjectCreationDefaultsSaved;

  @override
  State<ToolStrategySettingsPanel> createState() =>
      _ToolStrategySettingsPanelState();
}

class _ToolStrategySettingsPanelState extends State<ToolStrategySettingsPanel> {
  late String _mode;
  late bool _enabled;
  late bool _allowInlineFallback;
  late bool _autoPresentOptions;
  late bool _autoTaskPlan;
  late bool _autoWriteArtifacts;
  late bool _forceToolChoice;
  late bool _requireListBeforeRead;
  late bool _requireReadBeforeEdit;
  late String _toolPreviewMode;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ToolStrategySettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _sync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SettingsFormSection(
          title: '工具策略',
          description: '这里控制 AI 在已经暴露的工具里如何行动。它不负责权限放行，只负责执行风格与偏好。',
          child: Column(
            children: [
              SettingsLabeledDropdownField<String>(
                label: '策略模式',
                value: _mode,
                options: const [
                  SettingsDropdownOption(value: 'balanced', label: '平衡'),
                  SettingsDropdownOption(value: 'conservative', label: '保守'),
                  SettingsDropdownOption(value: 'proactive', label: '主动'),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _applyMode(value);
                  });
                },
              ),
              const SizedBox(height: 12),
              SettingsSwitchRow(
                label: '启用工具调用',
                value: _enabled,
                onChanged: (value) => setState(() {
                  _enabled = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许工具 JSON 兜底',
                value: _allowInlineFallback,
                onChanged: (value) => setState(() {
                  _allowInlineFallback = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '选项请求优先走工具',
                value: _autoPresentOptions,
                onChanged: (value) => setState(() {
                  _autoPresentOptions = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '复杂任务允许任务计划',
                value: _autoTaskPlan,
                onChanged: (value) => setState(() {
                  _autoTaskPlan = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '允许自动写入正式产物',
                value: _autoWriteArtifacts,
                onChanged: (value) => setState(() {
                  _autoWriteArtifacts = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '高级：请求级强制工具选择',
                value: _forceToolChoice,
                onChanged: (value) => setState(() {
                  _forceToolChoice = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '读取前鼓励先看目录',
                value: _requireListBeforeRead,
                onChanged: (value) => setState(() {
                  _requireListBeforeRead = value;
                }),
              ),
              const SizedBox(height: 10),
              SettingsSwitchRow(
                label: '修改前要求先读取',
                value: _requireReadBeforeEdit,
                onChanged: (value) => setState(() {
                  _requireReadBeforeEdit = value;
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SettingsFormSection(
          title: '工具展示',
          description: '这里控制工作台会话区对工具调用的默认展示方式，不再在主界面临时切换。',
          child: SettingsLabeledDropdownField<String>(
            label: '会话区工具预览',
            value: _toolPreviewMode,
            options: const [
              SettingsDropdownOption(
                value: ToolPreviewMode.compact,
                label: '紧凑',
              ),
              SettingsDropdownOption(
                value: ToolPreviewMode.detail,
                label: '细节',
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _toolPreviewMode = ToolPreviewMode.normalize(value);
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        ActionButton(
          label: '保存工具策略',
          expanded: true,
          icon: Icons.save_outlined,
          onPressed: () {
            widget.onSaved(<String, Object?>{
              'mode': _mode,
              'enabled': _enabled,
              'allow_inline_fallback': _allowInlineFallback,
              'auto_present_options': _autoPresentOptions,
              'auto_task_plan': _autoTaskPlan,
              'auto_write_artifacts': _autoWriteArtifacts,
              'force_tool_choice': _forceToolChoice,
              'require_list_before_read': _requireListBeforeRead,
              'require_read_before_edit': _requireReadBeforeEdit,
              'tool_preview_mode': _toolPreviewMode,
            });
          },
        ),
        if (widget.projectCreationDefaultsViewData != null &&
            widget.onProjectCreationDefaultsSaved != null) ...[
          const SizedBox(height: 16),
          ProjectCreationExpressionConstraintDefaultsPanel(
            viewData: widget.projectCreationDefaultsViewData!,
            onSaved: widget.onProjectCreationDefaultsSaved!,
          ),
        ],
      ],
    );
  }

  void _sync() {
    final normalized = const ToolStrategyService().normalize(widget.settings);
    _mode = normalized['mode'].toString();
    _enabled = normalized['enabled'] != false;
    _allowInlineFallback = normalized['allow_inline_fallback'] != false;
    _autoPresentOptions = normalized['auto_present_options'] != false;
    _autoTaskPlan = normalized['auto_task_plan'] != false;
    _autoWriteArtifacts = normalized['auto_write_artifacts'] != false;
    _forceToolChoice = normalized['force_tool_choice'] == true;
    _requireListBeforeRead = normalized['require_list_before_read'] != false;
    _requireReadBeforeEdit = normalized['require_read_before_edit'] != false;
    _toolPreviewMode = ToolPreviewMode.normalize(
      widget.settings['tool_preview_mode'],
    );
    // 中文注释: 这里不再调 _applyMode(_mode)——上面已按持久化的各开关回填，再套一次预设会把
    // 用户手动改过的开关整体覆盖回预设，导致"改开关→保存→重进"后改动丢失。
    // _applyMode 只服务于下拉选择预设的那一刻（onChanged 里调用）。
  }

  void _applyMode(String mode) {
    // 中文注释: 工具策略模式切换时同步映射到开关集合，避免模式下拉与具体策略值脱节。
    _mode = mode;
    switch (mode) {
      case ToolStrategyMode.conservative:
        _enabled = true;
        _allowInlineFallback = true;
        _autoPresentOptions = true;
        _autoTaskPlan = true;
        _autoWriteArtifacts = false;
        _forceToolChoice = false;
        _requireListBeforeRead = true;
        _requireReadBeforeEdit = true;
        return;
      case ToolStrategyMode.proactive:
        // 中文注释: "主动"必须与"平衡"有可见差异——否则下拉切换看起来没反应。
        // 主动模式在请求级强制模型走工具(force_tool_choice)，更积极地用工具而非内联作答。
        _enabled = true;
        _allowInlineFallback = true;
        _autoPresentOptions = true;
        _autoTaskPlan = true;
        _autoWriteArtifacts = true;
        _forceToolChoice = true;
        _requireListBeforeRead = true;
        _requireReadBeforeEdit = true;
        return;
      case ToolStrategyMode.balanced:
      default:
        _enabled = true;
        _allowInlineFallback = true;
        _autoPresentOptions = true;
        _autoTaskPlan = true;
        _autoWriteArtifacts = true;
        _forceToolChoice = false;
        _requireListBeforeRead = true;
        _requireReadBeforeEdit = true;
        return;
    }
  }
}
