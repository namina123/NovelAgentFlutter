import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 真实内容画布与空态画布分开，后续替换成编辑器时不会影响空态呈现逻辑。
    final surface = context.novelThemeSurfaces.panel;
    return DocumentWorkspaceCanvasFrame(
      title: widget.title,
      relativePath: widget.relativePath,
      status: widget.status,
      body: TextField(
        controller: _controller,
        expands: true,
        maxLines: null,
        minLines: null,
        onChanged: widget.isReadOnly ? null : widget.onChanged,
        readOnly: widget.isReadOnly,
        style: TextStyle(
          fontSize: 15,
          height: 1.65,
          color: surface.foregroundColor,
        ),
        decoration: const InputDecoration.collapsed(hintText: ''),
      ),
    );
  }
}
