import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

class DocumentContentCanvas extends StatefulWidget {
  const DocumentContentCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
    required this.onChanged,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;
  final ValueChanged<String> onChanged;

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title.trim().isEmpty ? '未命名草稿' : widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
              ),
            ),
            if (widget.relativePath.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.relativePath,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.mutedText,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              widget.status,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppPalette.lineStrong,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                expands: true,
                maxLines: null,
                minLines: null,
                onChanged: widget.onChanged,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.65,
                  color: AppPalette.text,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
