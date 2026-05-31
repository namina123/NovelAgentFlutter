import 'package:flutter/material.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';

class BookDeconstructionImportPanel extends StatefulWidget {
  const BookDeconstructionImportPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  State<BookDeconstructionImportPanel> createState() =>
      _BookDeconstructionImportPanelState();
}

class _BookDeconstructionImportPanelState
    extends State<BookDeconstructionImportPanel> {
  late final TextEditingController _sourceTitleController;
  late final TextEditingController _sourceContentController;
  late final TextEditingController _operatorNotesController;
  late final TextEditingController _styleSummaryController;
  late final TextEditingController _worldRulesController;
  late final TextEditingController _characterLinesController;
  late final TextEditingController _organizationLinesController;

  @override
  void initState() {
    super.initState();
    _sourceTitleController = TextEditingController(
      text: widget.viewData.sourceTitle,
    );
    _sourceContentController = TextEditingController(
      text: widget.viewData.sourceContent,
    );
    _operatorNotesController = TextEditingController(
      text: widget.viewData.operatorNotes,
    );
    _styleSummaryController = TextEditingController(
      text: widget.viewData.styleSummary,
    );
    _worldRulesController = TextEditingController(
      text: widget.viewData.worldRulesText,
    );
    _characterLinesController = TextEditingController(
      text: widget.viewData.characterLinesText,
    );
    _organizationLinesController = TextEditingController(
      text: widget.viewData.organizationLinesText,
    );
  }

  @override
  void didUpdateWidget(covariant BookDeconstructionImportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_sourceTitleController, widget.viewData.sourceTitle);
    _syncController(_sourceContentController, widget.viewData.sourceContent);
    _syncController(_operatorNotesController, widget.viewData.operatorNotes);
    _syncController(_styleSummaryController, widget.viewData.styleSummary);
    _syncController(_worldRulesController, widget.viewData.worldRulesText);
    _syncController(
      _characterLinesController,
      widget.viewData.characterLinesText,
    );
    _syncController(
      _organizationLinesController,
      widget.viewData.organizationLinesText,
    );
  }

  @override
  void dispose() {
    _sourceTitleController.dispose();
    _sourceContentController.dispose();
    _operatorNotesController.dispose();
    _styleSummaryController.dispose();
    _worldRulesController.dispose();
    _characterLinesController.dispose();
    _organizationLinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text('源文稿与结构补充', style: textTheme.titleSmall)),
              OutlinedButton.icon(
                onPressed: widget
                    .actionHandler
                    .onBookDeconstructionImportFileRequested,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('导入文本文件'),
              ),
            ],
          ),
        ),
        if (widget.viewData.sourceAbsolutePath.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              widget.viewData.sourceAbsolutePath,
              style: textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _sourceTitleController,
                decoration: const InputDecoration(
                  labelText: '来源标题',
                  hintText: '例如：某部待拆解的作品名',
                ),
                onChanged:
                    widget.actionHandler.onBookDeconstructionSourceTitleChanged,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sourceContentController,
                maxLines: 14,
                minLines: 14,
                decoration: const InputDecoration(
                  labelText: '源文稿',
                  hintText: '粘贴原文，或先从桌面端选择文本文件导入。',
                  alignLabelWithHint: true,
                ),
                onChanged: widget
                    .actionHandler
                    .onBookDeconstructionSourceContentChanged,
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('结构补充'),
                subtitle: const Text('可选，用于补强风格、世界规则与角色清单。'),
                children: [
                  TextField(
                    controller: _operatorNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '操作备注',
                      hintText: '例如：只保留世界规则与章纲，不导入角色细节。',
                    ),
                    onChanged: widget
                        .actionHandler
                        .onBookDeconstructionOperatorNotesChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _styleSummaryController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '风格提要',
                      hintText: '例如：商业节奏快、情节钩子强、叙述干净利落。',
                    ),
                    onChanged: widget
                        .actionHandler
                        .onBookDeconstructionStyleSummaryChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _worldRulesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '世界规则',
                      hintText: '每行一条规则。',
                      alignLabelWithHint: true,
                    ),
                    onChanged: widget
                        .actionHandler
                        .onBookDeconstructionWorldRulesChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _characterLinesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '角色清单',
                      hintText: '每行一个角色，可写成“姓名：摘要”。',
                      alignLabelWithHint: true,
                    ),
                    onChanged: widget
                        .actionHandler
                        .onBookDeconstructionCharacterLinesChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _organizationLinesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '组织清单',
                      hintText: '每行一个组织，可写成“组织：摘要”。',
                      alignLabelWithHint: true,
                    ),
                    onChanged: widget
                        .actionHandler
                        .onBookDeconstructionOrganizationLinesChanged,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.viewData.canBuildPreview
                    ? widget
                          .actionHandler
                          .onBookDeconstructionBuildPreviewRequested
                    : null,
                icon: const Icon(Icons.auto_fix_high_outlined),
                label: const Text('生成结构化预览'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _syncController(TextEditingController controller, String nextText) {
    if (controller.text == nextText) {
      return;
    }
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
  }
}
