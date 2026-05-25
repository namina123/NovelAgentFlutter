import 'package:flutter/material.dart';

import '../../../../app/layout/adaptive_page_frame.dart';
import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../contracts/project_assets_action_handler.dart';
import '../models/project_assets_view_data.dart';

class ProjectAssetsPage extends StatefulWidget {
  const ProjectAssetsPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectAssetsViewData viewData;
  final ProjectAssetsActionHandler actionHandler;

  @override
  State<ProjectAssetsPage> createState() => _ProjectAssetsPageState();
}

class _ProjectAssetsPageState extends State<ProjectAssetsPage> {
  late final TextEditingController _styleIdController;
  late final TextEditingController _styleNameController;
  late final TextEditingController _styleSummaryController;
  late final TextEditingController _styleGenreController;
  late final TextEditingController _styleToneController;
  late final TextEditingController _styleAudienceController;
  late final TextEditingController _styleTagsController;
  late final TextEditingController _styleGuardrailsController;
  late final TextEditingController _styleExamplesController;
  late final TextEditingController _styleInheritedIdsController;
  late bool _styleDefaultForProject;

  late final TextEditingController _foreshadowIdController;
  late final TextEditingController _foreshadowTitleController;
  late final TextEditingController _foreshadowSummaryController;
  late final TextEditingController _foreshadowStatusController;
  late final TextEditingController _foreshadowPlantedController;
  late final TextEditingController _foreshadowPayoffController;
  late final TextEditingController _foreshadowEntitiesController;
  late final TextEditingController _foreshadowPathsController;
  late final TextEditingController _foreshadowTriggersController;
  late final TextEditingController _foreshadowExpectationsController;
  late final TextEditingController _foreshadowTagsController;
  late final TextEditingController _foreshadowNotesController;

  @override
  void initState() {
    super.initState();
    _styleIdController = TextEditingController();
    _styleNameController = TextEditingController();
    _styleSummaryController = TextEditingController();
    _styleGenreController = TextEditingController();
    _styleToneController = TextEditingController();
    _styleAudienceController = TextEditingController();
    _styleTagsController = TextEditingController();
    _styleGuardrailsController = TextEditingController();
    _styleExamplesController = TextEditingController();
    _styleInheritedIdsController = TextEditingController();
    _foreshadowIdController = TextEditingController();
    _foreshadowTitleController = TextEditingController();
    _foreshadowSummaryController = TextEditingController();
    _foreshadowStatusController = TextEditingController();
    _foreshadowPlantedController = TextEditingController();
    _foreshadowPayoffController = TextEditingController();
    _foreshadowEntitiesController = TextEditingController();
    _foreshadowPathsController = TextEditingController();
    _foreshadowTriggersController = TextEditingController();
    _foreshadowExpectationsController = TextEditingController();
    _foreshadowTagsController = TextEditingController();
    _foreshadowNotesController = TextEditingController();
    _applyStyleEditor(widget.viewData.styleEditor);
    _applyForeshadowEditor(widget.viewData.foreshadowEditor);
  }

  @override
  void didUpdateWidget(covariant ProjectAssetsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.styleEditor.id != widget.viewData.styleEditor.id ||
        oldWidget.viewData.styleEditor.relativePath !=
            widget.viewData.styleEditor.relativePath) {
      _applyStyleEditor(widget.viewData.styleEditor);
    }
    if (oldWidget.viewData.foreshadowEditor.id !=
            widget.viewData.foreshadowEditor.id ||
        oldWidget.viewData.foreshadowEditor.relativePath !=
            widget.viewData.foreshadowEditor.relativePath) {
      _applyForeshadowEditor(widget.viewData.foreshadowEditor);
    }
  }

  @override
  void dispose() {
    _styleIdController.dispose();
    _styleNameController.dispose();
    _styleSummaryController.dispose();
    _styleGenreController.dispose();
    _styleToneController.dispose();
    _styleAudienceController.dispose();
    _styleTagsController.dispose();
    _styleGuardrailsController.dispose();
    _styleExamplesController.dispose();
    _styleInheritedIdsController.dispose();
    _foreshadowIdController.dispose();
    _foreshadowTitleController.dispose();
    _foreshadowSummaryController.dispose();
    _foreshadowStatusController.dispose();
    _foreshadowPlantedController.dispose();
    _foreshadowPayoffController.dispose();
    _foreshadowEntitiesController.dispose();
    _foreshadowPathsController.dispose();
    _foreshadowTriggersController.dispose();
    _foreshadowExpectationsController.dispose();
    _foreshadowTagsController.dispose();
    _foreshadowNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.actionHandler.onProjectAssetsBackRequested,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: SectionHeading(
                  title: widget.viewData.title,
                  subtitle: widget.viewData.description,
                ),
              ),
              ActionButton(
                label: '新建',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: widget.actionHandler.onProjectAssetsNewRequested,
              ),
              const SizedBox(width: 8),
              ActionButton(
                label: '导入资产包',
                icon: Icons.file_upload_outlined,
                compact: true,
                tone: ActionButtonTone.neutral,
                onPressed: _showImportDialog,
              ),
              const SizedBox(width: 8),
              ActionButton(
                label: '导出资产包',
                icon: Icons.inventory_2_outlined,
                compact: true,
                tone: ActionButtonTone.neutral,
                onPressed: _showExportDialog,
              ),
              const SizedBox(width: 8),
              ActionButton(
                label: '刷新',
                icon: Icons.refresh_rounded,
                compact: true,
                tone: ActionButtonTone.neutral,
                onPressed: widget.actionHandler.onProjectAssetsRefreshRequested,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.viewData.tabs
                .map(
                  (item) => ChoiceChip(
                    label: Text(item.label),
                    selected: item.id == widget.viewData.activeTabId,
                    onSelected: (_) {
                      widget.actionHandler.onProjectAssetsTabSelected(item.id);
                    },
                  ),
                )
                .toList(growable: false),
          ),
          if (widget.viewData.status.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.viewData.status,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PanelSurface(
                    padding: const EdgeInsets.all(12),
                    child: ListView.builder(
                      itemCount: widget.viewData.entries.length,
                      itemBuilder: (context, index) {
                        final item = widget.viewData.entries[index];
                        return ListTile(
                          dense: true,
                          selected: item.isSelected,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle.isEmpty
                                ? item.relativePath
                                : '${item.badge}｜${item.subtitle}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            widget.actionHandler.onProjectAssetsEntrySelected(
                              item.id,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: PanelSurface(
                    padding: const EdgeInsets.all(12),
                    child: widget.viewData.activeTabId == 'foreshadows'
                        ? _buildForeshadowEditor()
                        : _buildStyleEditor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: PanelSurface(
                    padding: const EdgeInsets.all(12),
                    child: _buildPreviewPanel(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleEditor() {
    final editor = widget.viewData.styleEditor;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: '风格中心',
            subtitle: editor.relativePath.trim().isEmpty
                ? '新建风格资产'
                : editor.relativePath,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _styleIdController,
            decoration: const InputDecoration(labelText: '风格 ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleNameController,
            decoration: const InputDecoration(labelText: '显示名'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleGenreController,
            decoration: const InputDecoration(labelText: '题材'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleToneController,
            decoration: const InputDecoration(labelText: '语气'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleAudienceController,
            decoration: const InputDecoration(labelText: '受众'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleTagsController,
            decoration: const InputDecoration(labelText: '标签（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleGuardrailsController,
            decoration: const InputDecoration(labelText: '约束（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleExamplesController,
            decoration: const InputDecoration(
              labelText: '示例路径（逗号分隔）',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleInheritedIdsController,
            decoration: const InputDecoration(
              labelText: '继承风格 ID（逗号分隔）',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _styleDefaultForProject,
            contentPadding: EdgeInsets.zero,
            title: const Text('设为项目默认风格'),
            onChanged: (value) {
              setState(() {
                _styleDefaultForProject = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _styleSummaryController,
            minLines: 10,
            maxLines: 16,
            decoration: const InputDecoration(labelText: '风格说明'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionButton(
                label: '保存风格',
                compact: true,
                onPressed: () {
                  widget.actionHandler.onProjectAssetsSaveStyleRequested(
                    _styleRequest(),
                  );
                },
              ),
              ActionButton(
                label: '删除风格',
                compact: true,
                tone: ActionButtonTone.danger,
                onPressed: () {
                  widget.actionHandler.onProjectAssetsDeleteRequested(
                    kind: 'style',
                    id: _styleIdController.text.trim(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForeshadowEditor() {
    final editor = widget.viewData.foreshadowEditor;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: '伏笔中心',
            subtitle: editor.relativePath.trim().isEmpty
                ? '新建伏笔资产'
                : editor.relativePath,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _foreshadowIdController,
            decoration: const InputDecoration(labelText: '伏笔 ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowTitleController,
            decoration: const InputDecoration(labelText: '标题'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowStatusController,
            decoration: const InputDecoration(labelText: '状态'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowPlantedController,
            decoration: const InputDecoration(labelText: '埋设章节路径'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowPayoffController,
            decoration: const InputDecoration(labelText: '回收章节路径'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowEntitiesController,
            decoration: const InputDecoration(labelText: '关联角色 ID（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowPathsController,
            decoration: const InputDecoration(labelText: '关联路径（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowTriggersController,
            decoration: const InputDecoration(labelText: '触发条件（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowExpectationsController,
            decoration: const InputDecoration(labelText: '回收预期（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowTagsController,
            decoration: const InputDecoration(labelText: '标签（逗号分隔）'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowSummaryController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(labelText: '摘要'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _foreshadowNotesController,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(labelText: '备注'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionButton(
                label: '保存伏笔',
                compact: true,
                onPressed: () {
                  widget.actionHandler.onProjectAssetsSaveForeshadowRequested(
                    _foreshadowRequest(),
                  );
                },
              ),
              ActionButton(
                label: '删除伏笔',
                compact: true,
                tone: ActionButtonTone.danger,
                onPressed: () {
                  widget.actionHandler.onProjectAssetsDeleteRequested(
                    kind: 'foreshadow',
                    id: _foreshadowIdController.text.trim(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final isForeshadow = widget.viewData.activeTabId == 'foreshadows';
    final style = widget.viewData.styleEditor;
    final foreshadow = widget.viewData.foreshadowEditor;
    final lines = isForeshadow
        ? <String>[
            '标题：${foreshadow.title}',
            '状态：${foreshadow.status}',
            '埋设：${foreshadow.plantedChapterPath}',
            '回收：${foreshadow.targetPayoffPath}',
            '',
            foreshadow.summary,
            if (foreshadow.notes.trim().isNotEmpty) ...[
              '',
              '备注：',
              foreshadow.notes,
            ],
          ]
        : <String>[
            '显示名：${style.displayName}',
            '题材：${style.genre}',
            '语气：${style.tone}',
            '受众：${style.audience}',
            '',
            style.summary,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: '资产预览',
          subtitle: isForeshadow
              ? (foreshadow.relativePath.trim().isEmpty
                    ? '未保存的伏笔资产'
                    : foreshadow.relativePath)
              : (style.relativePath.trim().isEmpty
                    ? '未保存的风格资产'
                    : style.relativePath),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: SelectableText(
              lines.join('\n').trim().isEmpty ? '这里会显示当前资产摘要。' : lines.join('\n'),
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppPalette.text,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImportDialog() async {
    final pathController = TextEditingController();
    var overwrite = false;
    final request = await showDialog<ProjectAssetBundleImportRequestViewData>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('导入资产包'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pathController,
                      decoration: const InputDecoration(labelText: '资产包绝对路径'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: overwrite,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('覆盖同 ID 资产'),
                      onChanged: (value) {
                        setState(() {
                          overwrite = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      ProjectAssetBundleImportRequestViewData(
                        absolutePath: pathController.text.trim(),
                        overwrite: overwrite,
                      ),
                    );
                  },
                  child: const Text('导入'),
                ),
              ],
            );
          },
        );
      },
    );
    pathController.dispose();
    if (request == null) {
      return;
    }
    widget.actionHandler.onProjectAssetsImportBundleRequested(request);
  }

  Future<void> _showExportDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final request = await showDialog<ProjectAssetBundleExportRequestViewData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导出资产包'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '资产包标题'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: '资产包说明'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  ProjectAssetBundleExportRequestViewData(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                  ),
                );
              },
              child: const Text('导出'),
            ),
          ],
        );
      },
    );
    titleController.dispose();
    descriptionController.dispose();
    if (request == null) {
      return;
    }
    widget.actionHandler.onProjectAssetsExportBundleRequested(request);
  }

  void _applyStyleEditor(StyleProfileEditorViewData editor) {
    _styleIdController.text = editor.id;
    _styleNameController.text = editor.displayName;
    _styleSummaryController.text = editor.summary;
    _styleGenreController.text = editor.genre;
    _styleToneController.text = editor.tone;
    _styleAudienceController.text = editor.audience;
    _styleTagsController.text = editor.tagsText;
    _styleGuardrailsController.text = editor.guardrailsText;
    _styleExamplesController.text = editor.examplePathsText;
    _styleInheritedIdsController.text = editor.inheritedIdsText;
    _styleDefaultForProject = editor.defaultForProject;
  }

  void _applyForeshadowEditor(ForeshadowRecordEditorViewData editor) {
    _foreshadowIdController.text = editor.id;
    _foreshadowTitleController.text = editor.title;
    _foreshadowStatusController.text = editor.status;
    _foreshadowSummaryController.text = editor.summary;
    _foreshadowPlantedController.text = editor.plantedChapterPath;
    _foreshadowPayoffController.text = editor.targetPayoffPath;
    _foreshadowEntitiesController.text = editor.relatedEntityIdsText;
    _foreshadowPathsController.text = editor.relatedPathsText;
    _foreshadowTriggersController.text = editor.triggerConditionsText;
    _foreshadowExpectationsController.text = editor.payoffExpectationsText;
    _foreshadowTagsController.text = editor.tagsText;
    _foreshadowNotesController.text = editor.notes;
  }

  StyleProfileEditorRequestViewData _styleRequest() {
    return StyleProfileEditorRequestViewData(
      id: _styleIdController.text,
      displayName: _styleNameController.text,
      summary: _styleSummaryController.text,
      genre: _styleGenreController.text,
      tone: _styleToneController.text,
      audience: _styleAudienceController.text,
      tagsText: _styleTagsController.text,
      guardrailsText: _styleGuardrailsController.text,
      examplePathsText: _styleExamplesController.text,
      inheritedIdsText: _styleInheritedIdsController.text,
      defaultForProject: _styleDefaultForProject,
    );
  }

  ForeshadowRecordEditorRequestViewData _foreshadowRequest() {
    return ForeshadowRecordEditorRequestViewData(
      id: _foreshadowIdController.text,
      title: _foreshadowTitleController.text,
      status: _foreshadowStatusController.text,
      summary: _foreshadowSummaryController.text,
      plantedChapterPath: _foreshadowPlantedController.text,
      targetPayoffPath: _foreshadowPayoffController.text,
      relatedEntityIdsText: _foreshadowEntitiesController.text,
      relatedPathsText: _foreshadowPathsController.text,
      triggerConditionsText: _foreshadowTriggersController.text,
      payoffExpectationsText: _foreshadowExpectationsController.text,
      tagsText: _foreshadowTagsController.text,
      notes: _foreshadowNotesController.text,
    );
  }
}
