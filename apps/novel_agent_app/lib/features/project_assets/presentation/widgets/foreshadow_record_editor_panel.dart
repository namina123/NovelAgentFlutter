import 'package:flutter/material.dart';

import '../models/project_assets_view_data.dart';

class ForeshadowRecordEditorPanel extends StatefulWidget {
  const ForeshadowRecordEditorPanel({
    super.key,
    required this.viewData,
    required this.onSaveRequested,
    required this.onDeleteRequested,
  });

  final ForeshadowRecordEditorViewData viewData;
  final ValueChanged<ForeshadowRecordEditorRequestViewData> onSaveRequested;
  final ValueChanged<String> onDeleteRequested;

  @override
  State<ForeshadowRecordEditorPanel> createState() =>
      _ForeshadowRecordEditorPanelState();
}

class _ForeshadowRecordEditorPanelState
    extends State<ForeshadowRecordEditorPanel> {
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _statusController;
  late final TextEditingController _summaryController;
  late final TextEditingController _plantedController;
  late final TextEditingController _payoffController;
  late final TextEditingController _entityController;
  late final TextEditingController _pathsController;
  late final TextEditingController _triggerController;
  late final TextEditingController _expectationController;
  late final TextEditingController _tagsController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _titleController = TextEditingController();
    _statusController = TextEditingController();
    _summaryController = TextEditingController();
    _plantedController = TextEditingController();
    _payoffController = TextEditingController();
    _entityController = TextEditingController();
    _pathsController = TextEditingController();
    _triggerController = TextEditingController();
    _expectationController = TextEditingController();
    _tagsController = TextEditingController();
    _notesController = TextEditingController();
    _apply(widget.viewData);
  }

  @override
  void didUpdateWidget(covariant ForeshadowRecordEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewData.id != widget.viewData.id ||
        oldWidget.viewData.relativePath != widget.viewData.relativePath) {
      _apply(widget.viewData);
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _statusController.dispose();
    _summaryController.dispose();
    _plantedController.dispose();
    _payoffController.dispose();
    _entityController.dispose();
    _pathsController.dispose();
    _triggerController.dispose();
    _expectationController.dispose();
    _tagsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('伏笔编辑', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _field(_idController, 'ID'),
        _field(_titleController, '标题'),
        _field(_statusController, '状态'),
        _field(_summaryController, '摘要', maxLines: 3),
        _field(_plantedController, '埋设章节路径'),
        _field(_payoffController, '目标回收路径'),
        _field(_entityController, '关联实体（逗号分隔）'),
        _field(_pathsController, '关联路径（逗号分隔）'),
        _field(_triggerController, '触发条件（逗号分隔）', maxLines: 3),
        _field(_expectationController, '回收预期（逗号分隔）', maxLines: 3),
        _field(_tagsController, '标签（逗号分隔）'),
        _field(_notesController, '备注', maxLines: 4),
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
                  : () => widget.onDeleteRequested(widget.viewData.id),
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

  void _apply(ForeshadowRecordEditorViewData viewData) {
    _idController.text = viewData.id;
    _titleController.text = viewData.title;
    _statusController.text = viewData.status;
    _summaryController.text = viewData.summary;
    _plantedController.text = viewData.plantedChapterPath;
    _payoffController.text = viewData.targetPayoffPath;
    _entityController.text = viewData.relatedEntityIdsText;
    _pathsController.text = viewData.relatedPathsText;
    _triggerController.text = viewData.triggerConditionsText;
    _expectationController.text = viewData.payoffExpectationsText;
    _tagsController.text = viewData.tagsText;
    _notesController.text = viewData.notes;
  }

  void _submit() {
    widget.onSaveRequested(
      ForeshadowRecordEditorRequestViewData(
        id: _idController.text,
        title: _titleController.text,
        status: _statusController.text,
        summary: _summaryController.text,
        plantedChapterPath: _plantedController.text,
        targetPayoffPath: _payoffController.text,
        relatedEntityIdsText: _entityController.text,
        relatedPathsText: _pathsController.text,
        triggerConditionsText: _triggerController.text,
        payoffExpectationsText: _expectationController.text,
        tagsText: _tagsController.text,
        notes: _notesController.text,
      ),
    );
  }
}
