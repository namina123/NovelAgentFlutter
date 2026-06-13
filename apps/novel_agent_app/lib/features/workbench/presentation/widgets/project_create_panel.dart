import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../models/project_create_request_view_data.dart';
import '../models/project_creation_phase.dart';
import '../models/project_runtime_baseline_option_view_data.dart';
import '../models/project_storage_strategy_option_view_data.dart';
import '../models/project_type_option_view_data.dart';
import 'project_continuity_input_panel.dart';
import 'project_runtime_baseline_option_tile.dart';
import 'project_storage_strategy_option_tile.dart';
import 'project_type_option_tile.dart';

class ProjectCreatePanel extends StatefulWidget {
  const ProjectCreatePanel({
    super.key,
    required this.title,
    required this.description,
    required this.projectsRootPath,
    required this.status,
    required this.draftTitle,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
    required this.storageStrategyOptions,
    required this.selectedStorageStrategyId,
    required this.creationPhase,
    required this.runtimeBaselineOptions,
    required this.selectedRuntimeBaselineId,
    required this.selectedProjectTypeRequiresRuntimeBaseline,
    this.continuityInput = const ProjectContinuityInputProfile(),
    required this.allowOpenExisting,
    required this.onOpenExistingRequested,
    required this.onBackRequested,
    required this.onCreateSubmitted,
  });

  final String title;
  final String description;
  final String projectsRootPath;
  final String status;
  final String draftTitle;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
  final List<ProjectStorageStrategyOptionViewData> storageStrategyOptions;
  final String selectedStorageStrategyId;
  final ProjectCreationPhase creationPhase;
  final List<ProjectRuntimeBaselineOptionViewData> runtimeBaselineOptions;
  final String selectedRuntimeBaselineId;
  final bool selectedProjectTypeRequiresRuntimeBaseline;
  final ProjectContinuityInputProfile continuityInput;
  final bool allowOpenExisting;
  final VoidCallback onOpenExistingRequested;
  final VoidCallback onBackRequested;
  final ValueChanged<ProjectCreateRequestViewData> onCreateSubmitted;

  @override
  State<ProjectCreatePanel> createState() => _ProjectCreatePanelState();
}

class _ProjectCreatePanelState extends State<ProjectCreatePanel> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late String _selectedProjectTypeId;
  late String _selectedStorageStrategyId;
  late String _selectedRuntimeBaselineId;
  late ProjectContinuityInputProfile _continuityInput;
  late bool _showAdvancedContinuity;
  String _lastDefaultTitle = '';

  @override
  void initState() {
    super.initState();
    _selectedProjectTypeId = _resolvedSelectedTypeId();
    _selectedStorageStrategyId = _resolvedSelectedStorageStrategyId();
    _selectedRuntimeBaselineId = _resolvedSelectedRuntimeBaselineId();
    _continuityInput = widget.continuityInput;
    _showAdvancedContinuity = _hasContinuityInput(_continuityInput);
    _lastDefaultTitle = _defaultTitleOf(_selectedProjectTypeId);
    _scrollController = ScrollController();
    _controller = TextEditingController(
      text: widget.draftTitle.trim().isEmpty
          ? _lastDefaultTitle
          : widget.draftTitle,
    );
  }

  @override
  void didUpdateWidget(covariant ProjectCreatePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 中文注释: 创建面板会跨阶段复用，因此外层视图数据变化时要把选择状态同步回当前 State。
    _selectedProjectTypeId = _resolvedSelectedTypeId();
    _selectedStorageStrategyId = _resolvedSelectedStorageStrategyId();
    _selectedRuntimeBaselineId = _resolvedSelectedRuntimeBaselineId();
    _continuityInput = widget.continuityInput;
    _lastDefaultTitle = _defaultTitleOf(_selectedProjectTypeId);
    if (widget.draftTitle != oldWidget.draftTitle &&
        widget.draftTitle.trim().isNotEmpty &&
        widget.draftTitle != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.draftTitle,
        selection: TextSelection.collapsed(offset: widget.draftTitle.length),
      );
    }
  }

  @override
  void dispose() {
    // 中文注释: 创建表单自己持有输入控制器，因此由表单自身负责释放。
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 这里统一承接“基础信息”和“运行基准补选”两阶段，但字段职责仍然按区块拆开。
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final selectedOption = _selectedOption();
    final phaseTitle = _phaseLabel(widget.creationPhase);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface.backgroundColor.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: surface.borderColor.withValues(alpha: 0.66),
                width: AppChrome.borderWidth,
              ),
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                primary: false,
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROJECT SETUP',
                      style: TextStyle(
                        color: colors.mutedTextColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: colors.mutedTextColor,
                        fontSize: 11.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: BoxDecoration(
                        color: colors.inputBackground.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.lineColor.withValues(alpha: 0.7),
                          width: AppChrome.borderWidth,
                        ),
                      ),
                      child: Text(
                        '创建位置：${widget.projectsRootPath}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.mutedTextColor,
                          fontSize: 11,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _StepStrip(
                      currentPhase: widget.creationPhase,
                      projectTypeRequiresRuntimeBaseline:
                          _selectedTypeRequiresRuntimeBaseline(),
                    ),
                    const SizedBox(height: 14),
                    _FieldBand(
                      title: '项目名',
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '输入要创建的小说项目名称',
                        ),
                        onSubmitted: _submit,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel(title: phaseTitle),
                    const SizedBox(height: 8),
                    ..._buildPhaseContent(selectedOption),
                    if (_supportsContinuityInput()) ...[
                      const SizedBox(height: 12),
                      _AdvancedContinuitySection(
                        expanded: _showAdvancedContinuity,
                        hasUserInput: _hasContinuityInput(_continuityInput),
                        compact:
                            widget.creationPhase !=
                            ProjectCreationPhase.projectType,
                        input: _continuityInput,
                        onToggle: () {
                          setState(() {
                            _showAdvancedContinuity = !_showAdvancedContinuity;
                          });
                        },
                        onChanged: _handleContinuityInputChanged,
                      ),
                    ],
                    if ((selectedOption?.description ?? '').trim().isNotEmpty &&
                        widget.creationPhase ==
                            ProjectCreationPhase.projectType) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: colors.panelBackground.withValues(alpha: 0.34),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.lineColor.withValues(alpha: 0.6),
                            width: AppChrome.borderWidth,
                          ),
                        ),
                        child: Text(
                          selectedOption!.description,
                          style: TextStyle(
                            color: colors.mutedTextColor,
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                    if (widget.status.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          color: colors.accentSoftColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.lineColor.withValues(alpha: 0.74),
                            width: AppChrome.borderWidth,
                          ),
                        ),
                        child: Text(
                          widget.status,
                          style: TextStyle(
                            color: colors.lineStrongColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: surface.borderColor.withValues(alpha: 0.66),
                width: AppChrome.borderWidth,
              ),
            ),
          ),
          child: Row(
            children: [
              if (_showBackButton()) ...[
                Expanded(
                  child: ActionButton(
                    label: '上一步',
                    icon: Icons.arrow_back_rounded,
                    expanded: true,
                    tone: ActionButtonTone.neutral,
                    onPressed: widget.onBackRequested,
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.allowOpenExisting) ...[
                Expanded(
                  child: ActionButton(
                    label: '打开已有项目',
                    icon: Icons.folder_open_outlined,
                    expanded: true,
                    tone: ActionButtonTone.neutral,
                    onPressed: widget.onOpenExistingRequested,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: ActionButton(
                  label: _submitButtonLabel(),
                  icon: Icons.add_business_outlined,
                  expanded: true,
                  tone: ActionButtonTone.warm,
                  onPressed: () => _submit(_controller.text),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPhaseContent(ProjectTypeOptionViewData? selectedOption) {
    switch (widget.creationPhase) {
      case ProjectCreationPhase.projectType:
        return _buildProjectTypeTiles();
      case ProjectCreationPhase.storageStrategy:
        final title = selectedOption?.title ?? '当前项目';
        return [
          ..._buildStorageStrategyTiles(),
          const SizedBox(height: 10),
          Text(
            '$title 将按这里选择的主存储策略创建项目骨架。',
            style: TextStyle(
              color: context.novelThemeColors.mutedTextColor,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ];
      case ProjectCreationPhase.runtimeBaseline:
        return _buildRuntimeBaselineTiles();
    }
  }

  List<Widget> _buildProjectTypeTiles() {
    final children = <Widget>[];
    for (var index = 0; index < widget.projectTypeOptions.length; index += 1) {
      final option = widget.projectTypeOptions[index];
      children.add(
        ProjectTypeOptionTile(
          option: option,
          isSelected: option.id == _selectedProjectTypeId,
          onTap: () => _handleProjectTypeChanged(option.id),
        ),
      );
      if (index != widget.projectTypeOptions.length - 1) {
        children.add(const SizedBox(height: 8));
      }
    }
    return children;
  }

  List<Widget> _buildStorageStrategyTiles() {
    final children = <Widget>[];
    for (
      var index = 0;
      index < widget.storageStrategyOptions.length;
      index += 1
    ) {
      final option = widget.storageStrategyOptions[index];
      children.add(
        ProjectStorageStrategyOptionTile(
          option: option,
          isSelected: option.id == _selectedStorageStrategyId,
          onTap: () => _handleStorageStrategyChanged(option.id),
        ),
      );
      if (index != widget.storageStrategyOptions.length - 1) {
        children.add(const SizedBox(height: 8));
      }
    }
    return children;
  }

  List<Widget> _buildRuntimeBaselineTiles() {
    final children = <Widget>[];
    for (
      var index = 0;
      index < widget.runtimeBaselineOptions.length;
      index += 1
    ) {
      final option = widget.runtimeBaselineOptions[index];
      children.add(
        ProjectRuntimeBaselineOptionTile(
          option: option,
          isSelected: option.id == _selectedRuntimeBaselineId,
          onTap: () => _handleRuntimeBaselineChanged(option.id),
        ),
      );
      if (index != widget.runtimeBaselineOptions.length - 1) {
        children.add(const SizedBox(height: 8));
      }
    }
    return children;
  }

  void _submit(String text) {
    // 中文注释: 表单只回传当前阶段已选的领域输入，真正的流程判断仍交给 core 创建用例。
    widget.onCreateSubmitted(
      ProjectCreateRequestViewData(
        title: text.trim(),
        projectTypeId: _selectedProjectTypeId,
        storageStrategyId: _selectedStorageStrategyId,
        runtimeBaselineId: _selectedRuntimeBaselineId,
        continuityInput: _continuityInput,
      ),
    );
  }

  void _handleProjectTypeChanged(String projectTypeId) {
    // 中文注释: 切换项目类型时，如果标题仍是旧默认值，就跟着切换默认标题，减少创建摩擦。
    final nextDefaultTitle = _defaultTitleOf(projectTypeId);
    final cleanTitle = _controller.text.trim();
    if (cleanTitle.isEmpty || cleanTitle == _lastDefaultTitle) {
      _controller.value = TextEditingValue(
        text: nextDefaultTitle,
        selection: TextSelection.collapsed(offset: nextDefaultTitle.length),
      );
    }
    setState(() {
      _selectedProjectTypeId = projectTypeId;
      _selectedStorageStrategyId = _resolvedSelectedStorageStrategyId();
      _selectedRuntimeBaselineId = '';
      _lastDefaultTitle = nextDefaultTitle;
    });
  }

  void _handleStorageStrategyChanged(String storageStrategyId) {
    // 中文注释: 存储策略切换不触发副作用，只更新表单选择。
    setState(() {
      _selectedStorageStrategyId = storageStrategyId;
    });
  }

  void _handleRuntimeBaselineChanged(String runtimeBaselineId) {
    // 中文注释: 运行基准属于长任务创建第二阶段，因此单独维护选择状态。
    setState(() {
      _selectedRuntimeBaselineId = runtimeBaselineId;
    });
  }

  void _handleContinuityInputChanged(ProjectContinuityInputProfile input) {
    setState(() {
      _continuityInput = input;
    });
  }

  bool _showBackButton() {
    return widget.creationPhase != ProjectCreationPhase.projectType;
  }

  String _phaseLabel(ProjectCreationPhase phase) {
    switch (phase) {
      case ProjectCreationPhase.projectType:
        return '项目类型';
      case ProjectCreationPhase.storageStrategy:
        return '主存储策略';
      case ProjectCreationPhase.runtimeBaseline:
        return '长任务运行基准';
    }
  }

  String _resolvedSelectedTypeId() {
    for (final option in widget.projectTypeOptions) {
      if (option.id == widget.selectedProjectTypeId) {
        return option.id;
      }
    }
    return widget.projectTypeOptions.isEmpty
        ? 'novel'
        : widget.projectTypeOptions.first.id;
  }

  String _resolvedSelectedStorageStrategyId() {
    for (final option in widget.storageStrategyOptions) {
      if (option.id == widget.selectedStorageStrategyId) {
        return option.id;
      }
    }
    return widget.storageStrategyOptions.isEmpty
        ? 'markdown_project_store'
        : widget.storageStrategyOptions.first.id;
  }

  String _resolvedSelectedRuntimeBaselineId() {
    for (final option in widget.runtimeBaselineOptions) {
      if (option.id == widget.selectedRuntimeBaselineId) {
        return option.id;
      }
    }
    return widget.runtimeBaselineOptions.isEmpty
        ? ''
        : widget.runtimeBaselineOptions.first.id;
  }

  ProjectTypeOptionViewData? _selectedOption() {
    for (final option in widget.projectTypeOptions) {
      if (option.id == _selectedProjectTypeId) {
        return option;
      }
    }
    return widget.projectTypeOptions.isEmpty
        ? null
        : widget.projectTypeOptions.first;
  }

  String _defaultTitleOf(String projectTypeId) {
    for (final option in widget.projectTypeOptions) {
      if (option.id == projectTypeId) {
        return option.defaultTitle;
      }
    }
    return widget.projectTypeOptions.isEmpty
        ? '未命名小说'
        : widget.projectTypeOptions.first.defaultTitle;
  }

  String _submitButtonLabel() {
    switch (widget.creationPhase) {
      case ProjectCreationPhase.projectType:
        return '下一步';
      case ProjectCreationPhase.storageStrategy:
        return _selectedTypeRequiresRuntimeBaseline() ? '下一步' : '创建并打开';
      case ProjectCreationPhase.runtimeBaseline:
        return '创建并打开';
    }
  }

  bool _selectedTypeRequiresRuntimeBaseline() {
    for (final option in widget.projectTypeOptions) {
      if (option.id == _selectedProjectTypeId) {
        return option.requiresRuntimeBaselineSelection;
      }
    }
    return false;
  }

  bool _supportsContinuityInput() {
    return _selectedProjectTypeId == 'novel' ||
        _selectedProjectTypeId == 'long_novel';
  }

  bool _hasContinuityInput(ProjectContinuityInputProfile input) {
    return input.usesMultipleWorlds ||
        input.usesBranchingRoutes ||
        input.usesReplayResets ||
        input.requiresScopedIdentityOverlays ||
        input.worldLabels.isNotEmpty ||
        input.notes.trim().isNotEmpty;
  }
}

class _AdvancedContinuitySection extends StatelessWidget {
  const _AdvancedContinuitySection({
    required this.expanded,
    required this.hasUserInput,
    required this.compact,
    required this.input,
    required this.onToggle,
    required this.onChanged,
  });

  final bool expanded;
  final bool hasUserInput;
  final bool compact;
  final ProjectContinuityInputProfile input;
  final VoidCallback onToggle;
  final ValueChanged<ProjectContinuityInputProfile> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.panelBackground.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.lineColor.withValues(alpha: 0.68),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colors.mutedTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '连续性高级设置',
                      style: TextStyle(
                        color: colors.textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    hasUserInput ? '已配置' : '可选',
                    style: TextStyle(
                      color: colors.mutedTextColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ProjectContinuityInputPanel(
                input: input,
                onChanged: onChanged,
                compact: compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({
    required this.currentPhase,
    required this.projectTypeRequiresRuntimeBaseline,
  });

  final ProjectCreationPhase currentPhase;
  final bool projectTypeRequiresRuntimeBaseline;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final phases = <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      ProjectCreationPhase.storageStrategy,
      if (projectTypeRequiresRuntimeBaseline)
        ProjectCreationPhase.runtimeBaseline,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: colors.panelBackground.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.lineColor.withValues(alpha: 0.68),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < phases.length; index += 1)
            _StepChip(
              index: index + 1,
              label: _stepLabel(phases[index]),
              active: phases[index] == currentPhase,
            ),
        ],
      ),
    );
  }

  String _stepLabel(ProjectCreationPhase phase) {
    switch (phase) {
      case ProjectCreationPhase.projectType:
        return '类型';
      case ProjectCreationPhase.storageStrategy:
        return '存储';
      case ProjectCreationPhase.runtimeBaseline:
        return '运行基准';
    }
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.active,
  });

  final int index;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final borderColor = active ? colors.accentColor : colors.lineColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
        color: active
            ? colors.accentSoftColor.withValues(alpha: 0.22)
            : colors.inputBackground.withValues(alpha: 0.56),
      ),
      child: Text(
        '$index. $label',
        style: TextStyle(
          color: active ? colors.lineStrongColor : colors.mutedTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Text(
      title,
      style: TextStyle(
        color: colors.mutedTextColor,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.18,
      ),
    );
  }
}

class _FieldBand extends StatelessWidget {
  const _FieldBand({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: colors.panelBackground.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.lineColor.withValues(alpha: 0.68),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.mutedTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
