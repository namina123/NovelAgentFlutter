import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/selector_option_view_data.dart';
import '../models/workspace_command_request_view_data.dart';
import 'conversation_model_strip.dart';
import 'selector_field.dart';

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
  late final TextEditingController _genreController;
  late final TextEditingController _premiseController;
  late final TextEditingController _notesController;
  late final TextEditingController _relativePathController;
  late final TextEditingController _entryNameController;
  late final TextEditingController _contentController;
  late final TextEditingController _sourcePathsController;
  late final TextEditingController _targetDirectoryController;
  late String _selectedTransitionTargetProjectTypeId;
  late String _selectedTransitionRuntimeBaselineId;
  late String _selectedSmartAnalysisProviderModelKey;
  late String _selectedSmartDeconstructionProviderModelKey;
  late bool _autoDeconstruct;
  late bool _smartAnalysis;
  late bool _smartDeconstruction;

  @override
  void initState() {
    super.initState();
    _projectTitleController = TextEditingController(
      text: widget.viewData.projectTitle,
    );
    _projectTypeController = TextEditingController(
      text: widget.viewData.projectType,
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
    _selectedTransitionTargetProjectTypeId =
        widget.viewData.transitionTargetProjectTypeId;
    _selectedTransitionRuntimeBaselineId =
        widget.viewData.transitionRuntimeBaselineId;
    _selectedSmartAnalysisProviderModelKey = _smartAnalysisProviderModelKeyOf(
      widget.viewData,
    );
    _selectedSmartDeconstructionProviderModelKey =
        _smartDeconstructionProviderModelKeyOf(widget.viewData);
    _autoDeconstruct = widget.viewData.autoDeconstruct;
    _smartAnalysis = widget.viewData.smartAnalysis;
    _smartDeconstruction = widget.viewData.smartDeconstruction;
  }

  @override
  void didUpdateWidget(covariant WorkspaceCommandOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData == widget.viewData) {
      return;
    }
    _syncController(_projectTitleController, widget.viewData.projectTitle);
    _syncController(_projectTypeController, widget.viewData.projectType);
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
    if (_selectedTransitionTargetProjectTypeId !=
            widget.viewData.transitionTargetProjectTypeId ||
        _selectedTransitionRuntimeBaselineId !=
            widget.viewData.transitionRuntimeBaselineId) {
      setState(() {
        _selectedTransitionTargetProjectTypeId =
            widget.viewData.transitionTargetProjectTypeId;
        _selectedTransitionRuntimeBaselineId =
            widget.viewData.transitionRuntimeBaselineId;
      });
    }
    if (_autoDeconstruct != widget.viewData.autoDeconstruct) {
      setState(() {
        _autoDeconstruct = widget.viewData.autoDeconstruct;
      });
    }
    if (_smartAnalysis != widget.viewData.smartAnalysis) {
      setState(() {
        _smartAnalysis = widget.viewData.smartAnalysis;
      });
    }
    final nextSmartAnalysisKey = _smartAnalysisProviderModelKeyOf(
      widget.viewData,
    );
    if (_selectedSmartAnalysisProviderModelKey != nextSmartAnalysisKey) {
      setState(() {
        _selectedSmartAnalysisProviderModelKey = nextSmartAnalysisKey;
      });
    }
    final nextSmartDeconstructionKey = _smartDeconstructionProviderModelKeyOf(
      widget.viewData,
    );
    if (_selectedSmartDeconstructionProviderModelKey !=
        nextSmartDeconstructionKey) {
      setState(() {
        _selectedSmartDeconstructionProviderModelKey =
            nextSmartDeconstructionKey;
      });
    }
    if (_smartDeconstruction != widget.viewData.smartDeconstruction) {
      setState(() {
        _smartDeconstruction = widget.viewData.smartDeconstruction;
      });
    }
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectTypeController.dispose();
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
                        onPressed: widget.viewData.isBusy
                            ? null
                            : widget.actionHandler.onWorkspaceCommandDismissed,
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
                        onPressed: widget.viewData.isBusy
                            ? null
                            : widget.actionHandler.onWorkspaceCommandDismissed,
                        child: const Text('取消'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: widget.viewData.isBusy ? null : _submit,
                        child: widget.viewData.isBusy
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.viewData.busyLabel.trim().isEmpty
                                        ? widget.viewData.confirmLabel
                                        : widget.viewData.busyLabel,
                                  ),
                                ],
                              )
                            : Text(widget.viewData.confirmLabel),
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
            _selectorField(
              label: '目标项目类型',
              value: _selectedTransitionTargetProjectTypeId,
              options: widget.viewData.transitionTargetProjectTypeOptions,
              enabled: !widget.viewData.isBusy,
              onSelected: (value) {
                setState(() {
                  _selectedTransitionTargetProjectTypeId = value;
                  final baselineStillValid = widget
                      .viewData
                      .transitionRuntimeBaselineOptions
                      .any(
                        (option) =>
                            option.id == _selectedTransitionRuntimeBaselineId,
                      );
                  if (!baselineStillValid) {
                    _selectedTransitionRuntimeBaselineId = '';
                  }
                });
              },
            ),
            if (widget.viewData.transitionRequiresRuntimeBaselineSelection)
              _selectorField(
                label: '运行基准',
                value: _selectedTransitionRuntimeBaselineId,
                options: widget.viewData.transitionRuntimeBaselineOptions,
                enabled: !widget.viewData.isBusy,
                emptyLabel: '请选择运行基准',
                onSelected: (value) {
                  setState(() {
                    _selectedTransitionRuntimeBaselineId = value;
                  });
                },
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: widget.viewData.isBusy ? null : _pickImportFiles,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('选择文件'),
                ),
                FilledButton.tonalIcon(
                  onPressed: widget.viewData.isBusy
                      ? null
                      : _pickImportDirectory,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('选择文件夹'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.viewData.importFileSelectionHint,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.mutedText,
              ),
            ),
            const SizedBox(height: 12),
            _field(
              _sourcePathsController,
              '已选来源',
              hint: '尚未选择文件或文件夹',
              maxLines: 6,
              readOnly: true,
            ),
            _field(_targetDirectoryController, '导入到项目目录', hint: '例如：assets'),
            _ImportOptionBlock(
              title: widget.viewData.projectType == 'book_deconstruction'
                  ? '生成结构化预演'
                  : '自动拆书',
              description: widget.viewData.importOutputHint,
              value: widget.viewData.canAutoDeconstruct
                  ? _autoDeconstruct
                  : false,
              enabled:
                  widget.viewData.canAutoDeconstruct && !widget.viewData.isBusy,
              onChanged: (value) {
                setState(() {
                  _autoDeconstruct = value;
                });
              },
            ),
            if (widget.viewData.canSmartDeconstruction) ...[
              const SizedBox(height: 8),
              _modelSelectorField(
                label: '智能拆书模型',
                value: _selectedSmartDeconstructionProviderModelKey,
                options: widget.viewData.smartDeconstructionModelOptions,
                enabled: !widget.viewData.isBusy,
                emptyLabel: '请选择拆书模型',
                onSelected: (value) {
                  setState(() {
                    _selectedSmartDeconstructionProviderModelKey = value;
                    if (value.trim().isEmpty) {
                      _smartDeconstruction = false;
                    }
                  });
                },
              ),
              _ImportOptionBlock(
                title: '使用模型辅助拆书',
                description:
                    _selectedSmartDeconstructionProviderModelKey.trim().isEmpty
                     ? '先选择模型后才能启用。'
                    : '启用后会先识别章节规则与清理规则，再交由程序执行拆分与清洗。',
                value: _smartDeconstruction,
                enabled:
                    !widget.viewData.isBusy &&
                    _selectedSmartDeconstructionProviderModelKey
                        .trim()
                        .isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    _smartDeconstruction = value;
                  });
                },
              ),
            ],
            if (widget.viewData.canSmartAnalyze) ...[
              const SizedBox(height: 8),
              _modelSelectorField(
                label: '分析模型',
                value: _selectedSmartAnalysisProviderModelKey,
                options: widget.viewData.smartAnalysisModelOptions,
                enabled: !widget.viewData.isBusy,
                emptyLabel: '请选择分析模型',
                onSelected: (value) {
                  setState(() {
                    _selectedSmartAnalysisProviderModelKey = value;
                    if (value.trim().isEmpty) {
                      _smartAnalysis = false;
                    }
                  });
                },
              ),
              _ImportOptionBlock(
                title: '智能分析',
                description:
                    _selectedSmartAnalysisProviderModelKey.trim().isEmpty
                    ? '先选择模型后才能启用。'
                    : '启用后会先判断导入内容更像正文、设定、大纲、角色资料还是参考材料。',
                value: _smartAnalysis,
                enabled:
                    !widget.viewData.isBusy &&
                    _selectedSmartAnalysisProviderModelKey.trim().isNotEmpty,
                onChanged: (value) {
                  setState(() {
                    _smartAnalysis = value;
                  });
                },
              ),
            ],
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

  Widget _selectorField({
    required String label,
    required String value,
    required List<SelectorOptionViewData> options,
    required ValueChanged<String> onSelected,
    bool enabled = true,
    String emptyLabel = '请选择',
  }) {
    final resolvedLabel = _selectorLabelOf(
      value: value,
      options: options,
      emptyLabel: emptyLabel,
    );
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
          SelectorField(
            label: label,
            value: resolvedLabel,
            options: options,
            onSelected: onSelected,
            enabled: enabled && (options.length > 1 || value.trim().isEmpty),
            showLabel: false,
          ),
        ],
      ),
    );
  }

  Widget _modelSelectorField({
    required String label,
    required String value,
    required List<SelectorOptionViewData> options,
    required ValueChanged<String> onSelected,
    bool enabled = true,
    String emptyLabel = '请选择',
  }) {
    final resolvedLabel = _selectorLabelOf(
      value: value,
      options: options,
      emptyLabel: emptyLabel,
    );
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
          ConversationModelStrip(
            modelLabel: resolvedLabel,
            modelOptions: options,
            onModelSelected: enabled ? onSelected : (_) {},
            showSurface: false,
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
      transitionTargetProjectTypeId: _selectedTransitionTargetProjectTypeId,
      transitionRuntimeBaselineId: _selectedTransitionRuntimeBaselineId,
      genre: _genreController.text,
      premise: _premiseController.text,
      notes: _notesController.text,
      relativePath: _relativePathController.text,
      entryName: _entryNameController.text,
      content: _contentController.text,
      sourcePathsText: _sourcePathsController.text,
      targetDirectory: _targetDirectoryController.text,
      autoDeconstruct: _autoDeconstruct,
      smartAnalysis: _smartAnalysis,
      smartAnalysisProviderId: _providerIdOfSmartAnalysisSelection(),
      smartAnalysisModelId: _modelIdOfSmartAnalysisSelection(),
      smartDeconstruction: _smartDeconstruction,
      smartDeconstructionProviderId:
          _providerIdOfSmartDeconstructionSelection(),
      smartDeconstructionModelId: _modelIdOfSmartDeconstructionSelection(),
    );
  }

  void _pickImportDirectory() {
    widget.actionHandler.onWorkspaceImportDirectoryPickRequested(
      _currentRequest().copyWith(pickDirectory: true),
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

  String _selectorLabelOf({
    required String value,
    required List<SelectorOptionViewData> options,
    required String emptyLabel,
  }) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) {
      return emptyLabel;
    }
    for (final option in options) {
      if (option.id == cleanValue) {
        return option.label;
      }
    }
    return cleanValue;
  }

  String _smartAnalysisProviderModelKeyOf(WorkspaceCommandViewData viewData) {
    final providerId = viewData.smartAnalysisProviderId.trim();
    final modelId = viewData.smartAnalysisModelId.trim();
    if (providerId.isEmpty || modelId.isEmpty) {
      return '';
    }
    return '$providerId::$modelId';
  }

  String _smartDeconstructionProviderModelKeyOf(
    WorkspaceCommandViewData viewData,
  ) {
    final providerId = viewData.smartDeconstructionProviderId.trim();
    final modelId = viewData.smartDeconstructionModelId.trim();
    if (providerId.isEmpty || modelId.isEmpty) {
      return '';
    }
    return '$providerId::$modelId';
  }

  String _providerIdOfSmartAnalysisSelection() {
    final key = _selectedSmartAnalysisProviderModelKey.trim();
    if (!key.contains('::')) {
      return '';
    }
    return key.split('::').first.trim();
  }

  String _modelIdOfSmartAnalysisSelection() {
    final key = _selectedSmartAnalysisProviderModelKey.trim();
    if (!key.contains('::')) {
      return '';
    }
    return key.substring(key.indexOf('::') + 2).trim();
  }

  String _providerIdOfSmartDeconstructionSelection() {
    final key = _selectedSmartDeconstructionProviderModelKey.trim();
    if (!key.contains('::')) {
      return '';
    }
    return key.split('::').first.trim();
  }

  String _modelIdOfSmartDeconstructionSelection() {
    final key = _selectedSmartDeconstructionProviderModelKey.trim();
    if (!key.contains('::')) {
      return '';
    }
    return key.substring(key.indexOf('::') + 2).trim();
  }
}

class _ImportOptionBlock extends StatelessWidget {
  const _ImportOptionBlock({
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Checkbox(
                    value: value,
                    onChanged: enabled
                        ? (nextValue) => onChanged(nextValue ?? false)
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: AppPalette.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
