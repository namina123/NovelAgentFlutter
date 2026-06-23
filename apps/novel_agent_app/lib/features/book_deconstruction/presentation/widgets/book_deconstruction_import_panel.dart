import 'package:flutter/material.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';

const String _importingOperationKind = 'importing_source';
const String _smartImportingOperationKind = 'smart_importing_source';
const String _buildingPreviewOperationKind = 'building_preview';

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

  @override
  void initState() {
    super.initState();
    _sourceTitleController = TextEditingController(
      text: widget.viewData.sourceTitle,
    );
    _sourceContentController = TextEditingController(
      text: widget.viewData.sourceContent,
    );
  }

  @override
  void didUpdateWidget(covariant BookDeconstructionImportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_sourceTitleController, widget.viewData.sourceTitle);
    _syncController(_sourceContentController, widget.viewData.sourceContent);
  }

  @override
  void dispose() {
    _sourceTitleController.dispose();
    _sourceContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isImporting =
        widget.viewData.operationKind == _importingOperationKind;
    final isSmartImporting =
        widget.viewData.operationKind == _smartImportingOperationKind;
    final isBuildingPreview =
        widget.viewData.operationKind == _buildingPreviewOperationKind;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('导入拆书源文稿', style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '导入书籍原文（文本 / Markdown / EPUB，或直接粘贴），点"拆书"分章、去噪、清洗。'
                    '拆书只做这件事；知识提取是下一步，可选可跳过。',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.viewData.isLoading
                      ? null
                      : widget
                            .actionHandler
                            .onBookDeconstructionImportFileRequested,
                  icon: isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(widget.viewData.importActionLabel),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message: widget.viewData.canSmartImport
                      ? '用已配置的模型做正文识别、分章与去噪'
                      : '需要先在设置里配置模型提供商',
                  child: OutlinedButton.icon(
                    onPressed: widget.viewData.canSmartImport
                        ? widget
                              .actionHandler
                              .onBookDeconstructionSmartImportRequested
                        : null,
                    icon: isSmartImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: Text(widget.viewData.smartImportActionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.viewData.sourceAbsolutePath.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('已导入来源', style: textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    widget.viewData.sourceAbsolutePath,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _sourceTitleController,
          enabled: !widget.viewData.isLoading,
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
          enabled: !widget.viewData.isLoading,
          maxLines: 14,
          minLines: 14,
          decoration: const InputDecoration(
            labelText: '源文稿',
            hintText: '粘贴原文，或先从桌面端选择文本 / Markdown / EPUB 导入。',
            alignLabelWithHint: true,
          ),
          onChanged:
              widget.actionHandler.onBookDeconstructionSourceContentChanged,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.viewData.canBuildPreview
              ? widget.actionHandler.onBookDeconstructionBuildPreviewRequested
              : null,
          icon: isBuildingPreview
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_outlined),
          label: Text(widget.viewData.buildPreviewActionLabel),
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
