import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../models/project_create_request_view_data.dart';
import '../models/project_type_option_view_data.dart';

class ProjectCreatePanel extends StatefulWidget {
  const ProjectCreatePanel({
    super.key,
    required this.projectsRootPath,
    required this.status,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
    required this.onCreateSubmitted,
  });

  final String projectsRootPath;
  final String status;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
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
    // 中文注释: 创建项目面板先只做最小可用骨架，保证入口真实可用，再逐步扩成完整向导。
    final selectedOption = _selectedOption();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '新建项目',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
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
        DropdownButtonFormField<String>(
          initialValue: _selectedProjectTypeId,
          decoration: const InputDecoration(
            labelText: '项目类型',
            hintText: '选择项目类型',
          ),
          items: widget.projectTypeOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.id,
                  child: Text(option.title),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _handleProjectTypeChanged(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          selectedOption?.description ?? '',
          style: const TextStyle(
            color: AppPalette.mutedText,
            fontSize: 12,
            height: 1.45,
          ),
        ),
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
        const Spacer(),
        ActionButton(
          label: '创建并打开',
          icon: Icons.add_business_outlined,
          expanded: true,
          tone: ActionButtonTone.warm,
          onPressed: () => _submit(_controller.text),
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
