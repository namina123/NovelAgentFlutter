import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../models/project_create_request_view_data.dart';
import '../models/project_type_option_view_data.dart';
import 'project_type_option_tile.dart';

class ProjectCreatePanel extends StatefulWidget {
  const ProjectCreatePanel({
    super.key,
    required this.projectsRootPath,
    required this.status,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
    required this.allowOpenExisting,
    required this.onOpenExistingRequested,
    required this.onCreateSubmitted,
  });

  final String projectsRootPath;
  final String status;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
  final bool allowOpenExisting;
  final VoidCallback onOpenExistingRequested;
  final ValueChanged<ProjectCreateRequestViewData> onCreateSubmitted;

  @override
  State<ProjectCreatePanel> createState() => _ProjectCreatePanelState();
}

class _ProjectCreatePanelState extends State<ProjectCreatePanel> {
  late final TextEditingController _controller;
  late String _selectedProjectTypeId;
  String _lastDefaultTitle = '';

  @override
  void initState() {
    super.initState();
    _selectedProjectTypeId = _resolvedSelectedTypeId();
    _lastDefaultTitle = _defaultTitleOf(_selectedProjectTypeId);
    _controller = TextEditingController(text: _lastDefaultTitle);
  }

  @override
  void dispose() {
    // 中文注释: 创建表单自己持有输入控制器，因此由表单自身负责释放。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 创建项目面板统一承接“无项目时先建项目”的主入口，桌面端可额外挂现有项目目录选择。
    final selectedOption = _selectedOption();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创建项目',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '先创建项目，再进入文件、会话和模型调用。',
          style: TextStyle(color: AppPalette.mutedText, fontSize: 12),
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
        Expanded(
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
                label: '创建并打开',
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
    // 中文注释: 表单只回传标题字符串，具体创建策略和目录去重仍交给外层控制器和核心用例。
    widget.onCreateSubmitted(
      ProjectCreateRequestViewData(
        title: text.trim(),
        projectTypeId: _selectedProjectTypeId,
      ),
    );
  }

  void _handleProjectTypeChanged(String projectTypeId) {
    // 中文注释: 切换项目类型时，如果标题仍是旧默认值，就跟着换成新类型的默认标题，减少创建表单摩擦。
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
      _lastDefaultTitle = nextDefaultTitle;
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
}
