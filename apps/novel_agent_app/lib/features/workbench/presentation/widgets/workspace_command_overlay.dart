import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/workspace_command_request_view_data.dart';

class WorkspaceCommandOverlay extends StatefulWidget {
  const WorkspaceCommandOverlay({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkspaceCommandViewData viewData;
  final ResourceManagerActionHandler actionHandler;

  @override
  State<WorkspaceCommandOverlay> createState() =>
      _WorkspaceCommandOverlayState();
}

class _WorkspaceCommandOverlayState extends State<WorkspaceCommandOverlay> {
  late final TextEditingController _projectTitleController;
  late final TextEditingController _projectTypeController;
  late final TextEditingController _transitionRuntimeBaselineController;
  late final TextEditingController _genreController;
  late final TextEditingController _premiseController;
  late final TextEditingController _notesController;
  late final TextEditingController _relativePathController;
  late final TextEditingController _entryNameController;
  late final TextEditingController _contentController;
  late final TextEditingController _sourcePathsController;
  late final TextEditingController _targetDirectoryController;
  late bool _autoDeconstruct;

  @override
  void initState() {
    super.initState();
    _projectTitleController = TextEditingController(
      text: widget.viewData.projectTitle,
    );
    _projectTypeController = TextEditingController(
      text: widget.viewData.projectType,
    );
    _transitionRuntimeBaselineController = TextEditingController(
      text: widget.viewData.transitionRuntimeBaselineId,
    );
    _genreController = TextEditingController(text: widget.viewData.genre);
    _premiseController = TextEditingController(text: widget.viewData.premise);
    _notesController = TextEditingController(text: widget.viewData.notes);
    _relativePathController = TextEditingController(
      text: widget.viewData.relativePath,
    );
    _entryNameController = TextEditingController(
      text: widget.viewData.entryName,
    );
    _contentController = TextEditingController(text: widget.viewData.content);
    _sourcePathsController = TextEditingController(
      text: widget.viewData.sourcePathsText,
    );
    _targetDirectoryController = TextEditingController(
      text: widget.viewData.targetDirectory,
    );
    _autoDeconstruct = widget.viewData.autoDeconstruct;
  }

  @override
  void didUpdateWidget(covariant WorkspaceCommandOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData == widget.viewData) {
      return;
    }
    _syncController(_projectTitleController, widget.viewData.projectTitle);
    _syncController(_projectTypeController, widget.viewData.projectType);
    _syncController(
      _transitionRuntimeBaselineController,
      widget.viewData.transitionRuntimeBaselineId,
    );
    _syncController(_genreController, widget.viewData.genre);
    _syncController(_premiseController, widget.viewData.premise);
    _syncController(_notesController, widget.viewData.notes);
    _syncController(_relativePathController, widget.viewData.relativePath);
    _syncController(_entryNameController, widget.viewData.entryName);
    _syncController(_contentController, widget.viewData.content);
    _syncController(_sourcePathsController, widget.viewData.sourcePathsText);
    _syncController(
      _targetDirectoryController,
      widget.viewData.targetDirectory,
    );
    if (_autoDeconstruct != widget.viewData.autoDeconstruct) {
      setState(() {
        _autoDeconstruct = widget.viewData.autoDeconstruct;
      });
    }
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectTypeController.dispose();
    _transitionRuntimeBaselineController.dispose();
    _genreController.dispose();
    _premiseController.dispose();
    _notesController.dispose();
    _relativePathController.dispose();
    _entryNameController.dispose();
    _contentController.dispose();
    _sourcePathsController.dispose();
    _targetDirectoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作区命令弹层只收集输入并回传请求，不直接执行项目副作用。
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
              maxHeight: 640,
              minWidth: 320,
            ),
            child: PanelSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.viewData.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.viewData.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.actionHandler.onWorkspaceCommandDismissed,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildBody(widget.viewData.mode),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (widget.viewData.status.trim().isNotEmpty) ...[
                    Text(
                      widget.viewData.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.mutedText,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      TextButton(
                        onPressed:
                            widget.actionHandler.onWorkspaceCommandDismissed,
                        child: const Text('取消'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _submit,
                        child: Text(widget.viewData.confirmLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(WorkspaceCommandMode mode) {
    switch (mode) {
      case WorkspaceCommandMode.editProjectInfo:
        return Column(
          children: [
            _field(_projectTitleController, '项目标题'),
            _field(_projectTypeController, '项目类型'),
            _field(_genreController, '题材'),
            _field(_premiseController, '核心设定'),
            _field(_notesController, '备注', maxLines: 5),
          ],
        );
      case WorkspaceCommandMode.transitionProjectType:
        return Column(
          children: [
            _field(_projectTypeController, '目标项目类型 ID', readOnly: true),
            _field(
              _transitionRuntimeBaselineController,
              '运行基准 ID',
              hint: '例如：continuous_autonomous',
            ),
          ],
        );
      case WorkspaceCommandMode.createFile:
        return Column(
          children: [
            _field(_relativePathController, '目标目录', hint: '例如：chapters'),
            _field(_entryNameController, '文件名', hint: '例如：chapter_01.md'),
            _field(_contentController, '初始内容', maxLines: 12),
          ],
        );
      case WorkspaceCommandMode.createFolder:
        return Column(
          children: [
            _field(_relativePathController, '父目录', hint: '例如：world'),
            _field(_entryNameController, '目录名', hint: '例如：sects'),
          ],
        );
      case WorkspaceCommandMode.importFiles:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _pickImportFiles,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('选择文件'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.viewData.importFileSelectionHint,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.mutedText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              _sourcePathsController,
              '已选文件',
              hint: '尚未选择文件',
              maxLines: 6,
              readOnly: true,
            ),
            _field(_targetDirectoryController, '导入到项目目录', hint: '例如：assets'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.viewData.canAutoDeconstruct
                      ? _autoDeconstruct
                      : false,
                  onChanged: widget.viewData.canAutoDeconstruct
                      ? (value) {
                          setState(() {
                            _autoDeconstruct = value ?? false;
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '自动拆书',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.viewData.importOutputHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppPalette.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String hint = '',
    int maxLines = 1,
    bool readOnly = false,
  }) {
    // 中文注释: 表单字段统一在这一层收口，后续替换视觉风格时不影响业务数据模型。
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppPalette.mutedText,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            minLines: maxLines,
            maxLines: maxLines,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    widget.actionHandler.onWorkspaceCommandSubmitted(_currentRequest());
  }

  void _pickImportFiles() {
    widget.actionHandler.onWorkspaceImportFilesPickRequested(_currentRequest());
  }

  WorkspaceCommandRequestViewData _currentRequest() {
    return WorkspaceCommandRequestViewData(
      mode: widget.viewData.mode,
      projectTitle: _projectTitleController.text,
      projectType: _projectTypeController.text,
      transitionTargetProjectTypeId:
          widget.viewData.transitionTargetProjectTypeId,
      transitionRuntimeBaselineId: _transitionRuntimeBaselineController.text,
      genre: _genreController.text,
      premise: _premiseController.text,
      notes: _notesController.text,
      relativePath: _relativePathController.text,
      entryName: _entryNameController.text,
      content: _contentController.text,
      sourcePathsText: _sourcePathsController.text,
      targetDirectory: _targetDirectoryController.text,
      autoDeconstruct: _autoDeconstruct,
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }
}
