import 'package:flutter/material.dart';

import '../../application/models/book_deconstruction_operation_kind.dart' show BookDeconstructionOperationKind;
import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';

/// 步骤①：导入源文稿（单一入口）——一个文件选择按钮 + 来源标题 + 粘贴框。
/// 模型辅助拆书的能力在步骤②（拆书）里以"使用模型"勾选体现，这里不再有独立的"智能拆书"按钮。
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
    final isImporting = widget.viewData.operationKind ==
        BookDeconstructionOperationKind.importingSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: widget.viewData.isLoading
              ? null
              : widget.actionHandler.onBookDeconstructionImportFileRequested,
          icon: isImporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(widget.viewData.importActionLabel),
        ),
        if (widget.viewData.sourceAbsolutePath.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '已导入来源：${widget.viewData.sourceAbsolutePath}',
            style: textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _sourceTitleController,
          enabled: !widget.viewData.isLoading,
          decoration: const InputDecoration(
            labelText: '来源标题',
            hintText: '例如：某部待拆书的作品名',
          ),
          onChanged:
              widget.actionHandler.onBookDeconstructionSourceTitleChanged,
        ),
        const SizedBox(height: 12),
        if (widget.viewData.sourceAbsolutePath.trim().isEmpty)
          TextField(
            controller: _sourceContentController,
            enabled: !widget.viewData.isLoading,
            maxLines: 12,
            minLines: 6,
            decoration: const InputDecoration(
              labelText: '源文稿',
              hintText: '粘贴原文，或点上方按钮选择文本 / Markdown / EPUB 文件。',
              alignLabelWithHint: true,
            ),
            onChanged:
                widget.actionHandler.onBookDeconstructionSourceContentChanged,
          )
        else
          _ImportedSourcePreview(sourceContent: widget.viewData.sourceContent),
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

/// 选文件导入后只渲染截断预览——把整本书灌进 TextField 会同步布局卡死 UI。
/// 完整正文已存盘，拆书会读取完整内容（snapshot.sourceContent 不截断）。
class _ImportedSourcePreview extends StatelessWidget {
  const _ImportedSourcePreview({required this.sourceContent});

  final String sourceContent;

  @override
  Widget build(BuildContext context) {
    const maxPreviewChars = 4000;
    final truncated = sourceContent.length <= maxPreviewChars
        ? sourceContent
        : '${sourceContent.substring(0, maxPreviewChars)}\n\n...（仅显示前 $maxPreviewChars 字预览，完整正文已存盘，拆书将读取完整内容）';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: SingleChildScrollView(
        child: SelectableText(
          truncated,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
