import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class DocumentTextEditorSurface extends StatefulWidget {
  const DocumentTextEditorSurface({
    super.key,
    required this.content,
    required this.isReadOnly,
    this.onChanged,
    this.hintText = '',
    this.showLineNumbers = true,
  });

  final String content;
  final bool isReadOnly;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final bool showLineNumbers;

  @override
  State<DocumentTextEditorSurface> createState() =>
      _DocumentTextEditorSurfaceState();
}

class _DocumentTextEditorSurfaceState extends State<DocumentTextEditorSurface> {
  static const double _editorTopPadding = 8;
  static const double _editorBottomPadding = 8;
  static const double _editorLeftPadding = 16;
  static const double _editorRightPadding = 8;
  static const double _gutterLeftPadding = 8;
  static const double _gutterRightPadding = 10;

  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  String _cachedGutterText = '1';
  String _cachedGutterSource = '';
  double _cachedGutterWidth = -1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content)
      ..addListener(_handleControllerChanged);
    _scrollController.addListener(_handleScrollChanged);
  }

  @override
  void didUpdateWidget(covariant DocumentTextEditorSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content &&
        _controller.text != widget.content) {
      final selection = _controller.selection;
      final nextOffset = math.min(
        selection.baseOffset < 0 ? widget.content.length : selection.baseOffset,
        widget.content.length,
      );
      _controller.value = TextEditingValue(
        text: widget.content,
        selection: TextSelection.collapsed(offset: nextOffset),
      );
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScrollChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final editorTextStyle = AppTypography.applyMonospaceFallback(
      TextStyle(
        fontSize: 15.4,
        height: 1.85,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
        fontFamily: 'Consolas',
        color: surface.foregroundColor,
      ),
    );
    final editorStrutStyle = StrutStyle(
      fontSize: 15.4,
      height: 1.85,
      forceStrutHeight: true,
      fontFamily: 'Consolas',
    );
    final lineNumberStyle = AppTypography.applyMonospaceFallback(
      TextStyle(
        fontSize: 15.4,
        height: 1.85,
        letterSpacing: 0,
        fontWeight: FontWeight.w500,
        fontFamily: 'Consolas',
        color: colors.mutedTextColor.withValues(alpha: 0.88),
      ),
    );
    final lineCount = _lineCountOf(_controller.text);
    final gutterWidth = widget.showLineNumbers
        ? math.max(52.0, 20 + lineCount.toString().length * 10.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableEditorWidth = math.max(
          120.0,
          constraints.maxWidth -
              gutterWidth -
              _editorLeftPadding -
              _editorRightPadding,
        );
        final gutterText = widget.showLineNumbers
            ? _gutterTextFor(
                contentWidth: availableEditorWidth,
                style: editorTextStyle,
                strutStyle: editorStrutStyle,
              )
            : '';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showLineNumbers)
              Container(
                width: gutterWidth,
                decoration: BoxDecoration(
                  color: surface.backgroundColor.withValues(alpha: 0.06),
                  border: Border(
                    right: BorderSide(
                      color: surface.borderColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: ClipRect(
                  child: AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      final offset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -offset),
                        child: child,
                      );
                    },
                    child: Padding(
                      key: const ValueKey('document_editor_line_number_gutter'),
                      padding: const EdgeInsets.fromLTRB(
                        _gutterLeftPadding,
                        _editorTopPadding,
                        _gutterRightPadding,
                        _editorBottomPadding,
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          gutterText,
                          textAlign: TextAlign.right,
                          style: lineNumberStyle,
                          strutStyle: editorStrutStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _editorLeftPadding,
                  _editorTopPadding,
                  _editorRightPadding,
                  _editorBottomPadding,
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: RawScrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    radius: const Radius.circular(999),
                    thickness: 8,
                    child: TextField(
                      controller: _controller,
                      scrollController: _scrollController,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      onChanged: widget.isReadOnly ? null : widget.onChanged,
                      readOnly: widget.isReadOnly,
                      textAlignVertical: TextAlignVertical.top,
                      cursorColor: colors.accentColor,
                      style: editorTextStyle,
                      strutStyle: editorStrutStyle,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        hintText: widget.isReadOnly ? '' : widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 14.6,
                          fontWeight: FontWeight.w500,
                          height: 1.7,
                          color: colors.mutedTextColor.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleScrollChanged() {
    if (mounted && widget.showLineNumbers) {
      setState(() {});
    }
  }

  int _lineCountOf(String text) {
    if (text.isEmpty) {
      return 1;
    }
    return '\n'.allMatches(text).length + 1;
  }

  String _gutterTextFor({
    required double contentWidth,
    required TextStyle style,
    required StrutStyle strutStyle,
  }) {
    final source = _controller.text;
    if (_cachedGutterSource == source &&
        (_cachedGutterWidth - contentWidth).abs() < 0.5) {
      return _cachedGutterText;
    }
    final lines = source.split('\n');
    final labels = <String>[];
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      strutStyle: strutStyle,
      maxLines: null,
    );
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      if (line.isEmpty) {
        labels.add('${index + 1}');
        continue;
      }
      painter.text = TextSpan(text: line, style: style);
      painter.layout(maxWidth: contentWidth);
      final visualLineCount = math.max(1, painter.computeLineMetrics().length);
      labels.add('${index + 1}');
      for (
        var visualIndex = 1;
        visualIndex < visualLineCount;
        visualIndex += 1
      ) {
        labels.add('');
      }
    }
    _cachedGutterSource = source;
    _cachedGutterWidth = contentWidth;
    _cachedGutterText = labels.join('\n');
    return _cachedGutterText;
  }
}
