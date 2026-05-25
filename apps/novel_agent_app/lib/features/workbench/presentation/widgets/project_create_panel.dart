import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../models/project_create_request_view_data.dart';
import '../models/project_creation_phase.dart';
import '../models/project_runtime_baseline_option_view_data.dart';
import '../models/project_storage_strategy_option_view_data.dart';
import '../models/project_type_option_view_data.dart';
import 'project_runtime_baseline_option_tile.dart';
import 'project_storage_strategy_option_tile.dart';
import 'project_type_option_tile.dart';

class ProjectCreatePanel extends StatefulWidget {
  const ProjectCreatePanel({
    super.key,
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
    required this.allowOpenExisting,
    required this.onOpenExistingRequested,
    required this.onCreateSubmitted,
  });

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
  final bool allowOpenExisting;
  final VoidCallback onOpenExistingRequested;
  final ValueChanged<ProjectCreateRequestViewData> onCreateSubmitted;

  @override
  State<ProjectCreatePanel> createState() => _ProjectCreatePanelState();
}

class _ProjectCreatePanelState extends State<ProjectCreatePanel> {
  late final TextEditingController _controller;
  late String _selectedProjectTypeId;
  late String _selectedStorageStrategyId;
  late String _selectedRuntimeBaselineId;
  String _lastDefaultTitle = '';

  @override
  void initState() {
    super.initState();
    _selectedProjectTypeId = _resolvedSelectedTypeId();
    _selectedStorageStrategyId = _resolvedSelectedStorageStrategyId();
    _selectedRuntimeBaselineId = _resolvedSelectedRuntimeBaselineId();
    _lastDefaultTitle = _defaultTitleOf(_selectedProjectTypeId);
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 这里统一承接“基础信息”和“运行基准补选”两阶段，但字段职责仍然按区块拆开。
    final selectedOption = _selectedOption();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.creationPhase == ProjectCreationPhase.runtimeBaseline
              ? '选择长任务运行基准'
              : '创建项目',
          style: const TextStyle(
            color: AppPalette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.creationPhase == ProjectCreationPhase.runtimeBaseline
              ? '先确定长任务要按哪种运行基准推进，再正式创建项目。'
              : '先创建项目，再进入文件、会话和模型调用。',
          style: const TextStyle(color: AppPalette.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          '创建位置：${widget.projectsRootPath}',
          style: const TextStyle(color: AppPalette.mutedText, fontSize: 12),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: '项目名',
            hintText: '输入要创建的小说项目名称',
          ),
          onSubmitted: _submit,
        ),
        const SizedBox(height: 12),
        const Text(
          '项目类型',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 144,
          child: ListView.separated(
            itemCount: widget.projectTypeOptions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = widget.projectTypeOptions[index];
              return ProjectTypeOptionTile(
                option: option,
                isSelected: option.id == _selectedProjectTypeId,
                onTap: () => _handleProjectTypeChanged(option.id),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '主存储策略',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 116,
          child: ListView.separated(
            itemCount: widget.storageStrategyOptions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final option = widget.storageStrategyOptions[index];
              return ProjectStorageStrategyOptionTile(
                option: option,
                isSelected: option.id == _selectedStorageStrategyId,
                onTap: () => _handleStorageStrategyChanged(option.id),
              );
            },
          ),
        ),
        if ((selectedOption?.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            selectedOption!.description,
            style: const TextStyle(
              color: AppPalette.mutedText,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
        if (widget.creationPhase == ProjectCreationPhase.runtimeBaseline) ...[
          const SizedBox(height: 12),
          const Text(
            '长任务运行基准',
            style: TextStyle(
              color: AppPalette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: widget.runtimeBaselineOptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = widget.runtimeBaselineOptions[index];
                return ProjectRuntimeBaselineOptionTile(
                  option: option,
                  isSelected: option.id == _selectedRuntimeBaselineId,
                  onTap: () => _handleRuntimeBaselineChanged(option.id),
                );
              },
            ),
          ),
        ] else
          const Spacer(),
        if (widget.status.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.status,
            style: const TextStyle(
              color: AppPalette.lineStrong,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (widget.allowOpenExisting) ...[
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
      ],
    );
  }

  void _submit(String text) {
    // 中文注释: 表单只回传当前阶段已选的领域输入，真正的流程判断仍交给 core 创建用例。
    widget.onCreateSubmitted(
      ProjectCreateRequestViewData(
        title: text.trim(),
        projectTypeId: _selectedProjectTypeId,
        storageStrategyId: _selectedStorageStrategyId,
        runtimeBaselineId: _selectedRuntimeBaselineId,
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
    if (widget.creationPhase == ProjectCreationPhase.runtimeBaseline) {
      return '创建并打开';
    }
    return _selectedTypeRequiresRuntimeBaseline() ? '下一步' : '创建并打开';
  }

  bool _selectedTypeRequiresRuntimeBaseline() {
    for (final option in widget.projectTypeOptions) {
      if (option.id == _selectedProjectTypeId) {
        return option.requiresRuntimeBaselineSelection;
      }
    }
    return false;
  }
}
