import 'package:flutter/material.dart';

import '../../../../app/theme/app_palette.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../contracts/prompt_templates_action_handler.dart';
import '../models/prompt_templates_view_data.dart';

class PromptTemplatesPage extends StatefulWidget {
  const PromptTemplatesPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final PromptTemplatesViewData viewData;
  final PromptTemplatesActionHandler actionHandler;

  @override
  State<PromptTemplatesPage> createState() => _PromptTemplatesPageState();
}

class _PromptTemplatesPageState extends State<PromptTemplatesPage> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  late final TextEditingController _variablesController;
  late String _scope;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _contentController = TextEditingController();
    _variablesController = TextEditingController();
    _applyEditor(widget.viewData.editor);
  }

  @override
  void didUpdateWidget(covariant PromptTemplatesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.selectedTemplateId !=
            widget.viewData.selectedTemplateId ||
        oldWidget.viewData.editor.id != widget.viewData.editor.id) {
      _applyEditor(widget.viewData.editor);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _variablesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkspacePageScaffold(
      header: WorkspacePageHeader(
        title: widget.viewData.title,
        subtitle: widget.viewData.description,
        onBackRequested: widget.actionHandler.onPromptTemplatesBackRequested,
        actions: [
          ActionButton(
            label: '新建',
            icon: Icons.add_rounded,
            compact: true,
            onPressed: widget.actionHandler.onPromptTemplatesNewRequested,
          ),
          ActionButton(
            label: '刷新',
            icon: Icons.refresh_rounded,
            compact: true,
            tone: ActionButtonTone.neutral,
            onPressed: widget.actionHandler.onPromptTemplatesRefreshRequested,
          ),
        ],
      ),
      statusText: widget.viewData.status,
      body: WorkspacePaneLayout(
        breakpoint: 1320,
        leadingPaneWidth: 280,
        trailingPaneWidth: 360,
        leadingCompactHeight: 240,
        trailingCompactHeight: 280,
        leadingPane: PanelSurface(
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
                  item.subtitle,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  widget.actionHandler.onPromptTemplatesTemplateSelected(
                    item.id,
                  );
                },
              );
            },
          ),
        ),
        mainPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: '模板编辑',
                  subtitle:
                      widget.viewData.editor.relativePath.trim().isNotEmpty
                      ? widget.viewData.editor.relativePath
                      : (widget.viewData.editor.isBuiltin ? '内置模板' : '新模板'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: '模板 ID'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '模板名'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>('template-scope-$_scope'),
                  initialValue: _scope,
                  decoration: const InputDecoration(labelText: '作用域'),
                  items: widget.viewData.scopeOptions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    setState(() {
                      _scope = value ?? 'project';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: '说明'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  minLines: 10,
                  maxLines: 18,
                  decoration: const InputDecoration(labelText: '模板正文'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _variablesController,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: '预览变量 JSON'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionButton(
                      label: '预览',
                      compact: true,
                      onPressed: () {
                        widget.actionHandler.onPromptTemplatesPreviewRequested(
                          _request(),
                        );
                      },
                    ),
                    ActionButton(
                      label: '保存',
                      compact: true,
                      onPressed: () {
                        widget.actionHandler.onPromptTemplatesSaveRequested(
                          _request(),
                        );
                      },
                    ),
                    ActionButton(
                      label: '恢复内置',
                      compact: true,
                      tone: ActionButtonTone.warm,
                      onPressed: () {
                        widget.actionHandler.onPromptTemplatesRestoreRequested(
                          _idController.text.trim(),
                        );
                      },
                    ),
                    ActionButton(
                      label: '删除覆盖',
                      compact: true,
                      tone: ActionButtonTone.danger,
                      onPressed: () {
                        widget.actionHandler.onPromptTemplatesDeleteRequested(
                          _idController.text.trim(),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        trailingPane: PanelSurface(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(title: '预览结果'),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.viewData.previewText.trim().isEmpty
                        ? '这里会显示模板渲染结果。'
                        : widget.viewData.previewText,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: AppPalette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyEditor(PromptTemplateEditorViewData editor) {
    _idController.text = editor.id;
    _nameController.text = editor.name;
    _descriptionController.text = editor.description;
    _contentController.text = editor.content;
    _variablesController.text = editor.variablesJson;
    _scope = editor.scope.isEmpty ? 'project' : editor.scope;
  }

  PromptTemplateEditorRequestViewData _request() {
    return PromptTemplateEditorRequestViewData(
      id: _idController.text,
      name: _nameController.text,
      scope: _scope,
      description: _descriptionController.text,
      content: _contentController.text,
      variablesJson: _variablesController.text,
    );
  }
}
