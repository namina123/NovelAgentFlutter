import 'package:flutter/material.dart';

import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';
import 'workbench_visual_style.dart';

class DocumentContentCanvas extends StatefulWidget {
  const DocumentContentCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
    required this.onChanged,
    this.isReadOnly = false,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;
  final ValueChanged<String> onChanged;
  final bool isReadOnly;

  @override
  State<DocumentContentCanvas> createState() => _DocumentContentCanvasState();
}

class _DocumentContentCanvasState extends State<DocumentContentCanvas> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(covariant DocumentContentCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content &&
        _controller.text != widget.content) {
      _controller.value = TextEditingValue(
        text: widget.content,
        selection: TextSelection.collapsed(offset: widget.content.length),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final paragraphCount = '\n\n'.allMatches(widget.content).length + 1;
    final editorTextStyle = AppTypography.applyMonospaceFallback(
      TextStyle(
        fontSize: 16.2,
        height: 1.9,
        letterSpacing: 0.01,
        fontWeight: FontWeight.w500,
        fontFamily: 'Consolas',
        color: surface.foregroundColor,
      ),
    );
    final lineCount = '\n'.allMatches(widget.content).length + 1;
    final characterCount = widget.content.characters.length;
    return DocumentWorkspaceCanvasFrame(
      title: widget.title,
      relativePath: widget.relativePath,
      status: widget.status,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(visual.surfaceRadius + 1),
          border: Border.all(color: surface.borderColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '源文件',
                    style: TextStyle(
                      fontSize: visual.compactLabelFontSize,
                      fontWeight: FontWeight.w800,
                      color: colors.mutedTextColor,
                    ),
                  ),
                  _EditorMetaLabel(label: '$lineCount 行'),
                  _EditorMetaLabel(label: '$characterCount 字符'),
                  _EditorMetaLabel(label: '$paragraphCount 段'),
                  _EditorMetaLabel(
                    label: widget.isReadOnly ? '只读' : '可编辑',
                    emphasized: !widget.isReadOnly,
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: surface.borderColor.withValues(alpha: 0.08),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface.backgroundColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: surface.borderColor.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 20, 20),
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
                      child: Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: false,
                        child: TextField(
                          controller: _controller,
                          scrollController: _scrollController,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          onChanged: widget.isReadOnly
                              ? null
                              : widget.onChanged,
                          readOnly: widget.isReadOnly,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: colors.accentColor,
                          style: editorTextStyle,
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: widget.isReadOnly ? '' : '开始编写当前文档...',
                            hintStyle: TextStyle(
                              fontSize: 14.8,
                              fontWeight: FontWeight.w500,
                              height: 1.72,
                              color: colors.mutedTextColor.withValues(
                                alpha: 0.74,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorMetaLabel extends StatelessWidget {
  const _EditorMetaLabel({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.accentSoftColor.withValues(alpha: 0.24)
            : surface.backgroundColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: visual.metaFontSize,
          fontWeight: FontWeight.w700,
          color: emphasized ? colors.lineStrongColor : colors.mutedTextColor,
        ),
      ),
    );
  }
}
