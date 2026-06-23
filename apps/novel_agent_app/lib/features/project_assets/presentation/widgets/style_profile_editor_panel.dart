import 'package:flutter/material.dart';

import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../models/project_assets_view_data.dart';

class StyleProfileEditorPanel extends StatefulWidget {
  const StyleProfileEditorPanel({
    super.key,
    required this.viewData,
    required this.onSaveRequested,
    required this.onDeleteRequested,
  });

  final StyleProfileEditorViewData viewData;
  final ValueChanged<StyleProfileEditorRequestViewData> onSaveRequested;
  final ValueChanged<String> onDeleteRequested;

  @override
  State<StyleProfileEditorPanel> createState() => _StyleProfileEditorPanelState();
}

class _StyleProfileEditorPanelState extends State<StyleProfileEditorPanel> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;
  late final TextEditingController _genreController;
  late final TextEditingController _toneController;
  late final TextEditingController _audienceController;
  late final TextEditingController _tagsController;
  late final TextEditingController _guardrailsController;
  late final TextEditingController _examplesController;
  late final TextEditingController _inheritedController;
  late bool _defaultForProject;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _nameController = TextEditingController();
    _summaryController = TextEditingController();
    _genreController = TextEditingController();
    _toneController = TextEditingController();
    _audienceController = TextEditingController();
    _tagsController = TextEditingController();
    _guardrailsController = TextEditingController();
    _examplesController = TextEditingController();
    _inheritedController = TextEditingController();
    _apply(widget.viewData);
  }

  @override
  void didUpdateWidget(covariant StyleProfileEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.viewData.id;
    if (oldId != widget.viewData.id ||
        oldWidget.viewData.relativePath != widget.viewData.relativePath) {
      // 中文注释: 切换记录前，若当前有未保存修改，先落盘旧记录，避免被 _apply 静默覆盖丢失。
      if (oldId.trim().isNotEmpty && _isDirtyAgainst(oldWidget.viewData)) {
        final pending = _buildSaveRequest(id: oldId);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onSaveRequested(pending);
          }
        });
      }
      _apply(widget.viewData);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _summaryController.dispose();
    _genreController.dispose();
    _toneController.dispose();
    _audienceController.dispose();
    _tagsController.dispose();
    _guardrailsController.dispose();
    _examplesController.dispose();
    _inheritedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('风格编辑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field(_idController, 'ID'),
        _field(_nameController, '名称'),
        _field(_summaryController, '摘要', maxLines: 3),
        _field(_genreController, '题材'),
        _field(_toneController, '语气'),
        _field(_audienceController, '受众'),
        _field(_tagsController, '标签（逗号分隔）'),
        _field(_guardrailsController, '风格约束（逗号分隔）', maxLines: 3),
        _field(_examplesController, '示例路径（逗号分隔）'),
        _field(_inheritedController, '继承来源（逗号分隔）'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('设为项目默认风格'),
          value: _defaultForProject,
          onChanged: (value) => setState(() => _defaultForProject = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: _submit,
              child: const Text('保存'),
            ),
            OutlinedButton(
              onPressed: widget.viewData.id.trim().isEmpty
                  ? null
                  : () async {
                      final confirmed = await showConfirmationDialog(
                        context,
                        title: '删除该风格记录？',
                        message: '删除后不可恢复，确认删除？',
                        confirmLabel: '删除',
                      );
                      if (!mounted) {
                        return;
                      }
                      if (confirmed) {
                        widget.onDeleteRequested(widget.viewData.id);
                      }
                    },
              child: const Text('删除'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _apply(StyleProfileEditorViewData viewData) {
    _idController.text = viewData.id;
    _nameController.text = viewData.displayName;
    _summaryController.text = viewData.summary;
    _genreController.text = viewData.genre;
    _toneController.text = viewData.tone;
    _audienceController.text = viewData.audience;
    _tagsController.text = viewData.tagsText;
    _guardrailsController.text = viewData.guardrailsText;
    _examplesController.text = viewData.examplePathsText;
    _inheritedController.text = viewData.inheritedIdsText;
    _defaultForProject = viewData.defaultForProject;
  }

  void _submit() {
    widget.onSaveRequested(_buildSaveRequest(id: _idController.text));
  }

  /// 当前编辑器是否有别于 [viewData]（即存在未保存的修改）。
  bool _isDirtyAgainst(StyleProfileEditorViewData viewData) {
    if (_nameController.text != viewData.displayName) return true;
    if (_summaryController.text != viewData.summary) return true;
    if (_genreController.text != viewData.genre) return true;
    if (_toneController.text != viewData.tone) return true;
    if (_audienceController.text != viewData.audience) return true;
    if (_tagsController.text != viewData.tagsText) return true;
    if (_guardrailsController.text != viewData.guardrailsText) return true;
    if (_examplesController.text != viewData.examplePathsText) return true;
    if (_inheritedController.text != viewData.inheritedIdsText) return true;
    if (_defaultForProject != viewData.defaultForProject) return true;
    return false;
  }

  StyleProfileEditorRequestViewData _buildSaveRequest({required String id}) {
    return StyleProfileEditorRequestViewData(
      id: id,
      displayName: _nameController.text,
      summary: _summaryController.text,
      genre: _genreController.text,
      tone: _toneController.text,
      audience: _audienceController.text,
      tagsText: _tagsController.text,
      guardrailsText: _guardrailsController.text,
      examplePathsText: _examplesController.text,
      inheritedIdsText: _inheritedController.text,
      defaultForProject: _defaultForProject,
    );
  }
}
