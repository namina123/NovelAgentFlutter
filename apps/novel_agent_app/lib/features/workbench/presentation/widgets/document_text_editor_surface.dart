import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // 中文注释: 编辑器行高 = 字号 × 行距，与下方 editorStrutStyle 一致，查找时据此估算滚动位置。
  static const double _estimatedLineHeight = 15.4 * 1.85;

  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();
  // 中文注释: 查找栏相关状态——全部收在本组件内：surface 持有正文 TextEditingController，
  // 是唯一直接知道全文又能定位/选中匹配的位置，无需把查找逻辑外溢到控制器/视图数据。
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  bool _findVisible = false;
  String _query = '';
  List<_TextMatch> _matches = const <_TextMatch>[];
  int _currentMatch = -1;
  // 中文注释: 默认大小写不敏感（与现代编辑器一致）；Aa 按钮切换为精确匹配。
  bool _caseSensitive = false;

  String _cachedGutterText = '1';
  String _cachedGutterSource = '';
  double _cachedGutterWidth = -1;
  // 中文注释: 行号重排是 O(N) 的 TextPainter.layout——长章节每键都重算会卡。
  // 用 debounce 把行号刷新延后到停顿时(正文本身经 onChanged 即时保存，行号晚 150ms 无妨)。
  Timer? _gutterRefreshTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content)
      ..addListener(_handleControllerChanged);
    _scrollController.addListener(_handleScrollChanged);
    _findController.addListener(_handleFindControllerChanged);
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
      if (_findVisible) {
        // 中文注释: 外部内容更新后匹配偏移已失效，重算一次并就近归位。
        WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMatches());
      }
    }
  }

  @override
  void dispose() {
    _gutterRefreshTimer?.cancel();
    _controller
      ..removeListener(_handleControllerChanged)
      ..dispose();
    _scrollController
      ..removeListener(_handleScrollChanged)
      ..dispose();
    _editorFocusNode.dispose();
    _findController
      ..removeListener(_handleFindControllerChanged)
      ..dispose();
    _findFocusNode.dispose();
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

    return CallbackShortcuts(
      // 中文注释: 写作面的查找快捷键——Ctrl+F 展开/聚焦查找栏，Escape 收起；
      // F3 / Ctrl+G 与 Shift+F3 / Ctrl+Shift+G 在不离开正文键盘的情况下跳转下一个/上一个匹配，
      // 查找栏关闭后仍保留最近一次的匹配结果，便于边读边跳。
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _showFindBar,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_findVisible) {
            _hideFindBar();
          }
        },
        const SingleActivator(LogicalKeyboardKey.f3): _findNext,
        const SingleActivator(LogicalKeyboardKey.f3, shift: true):
            _findPrevious,
        const SingleActivator(LogicalKeyboardKey.keyG, control: true):
            _findNext,
        const SingleActivator(
          LogicalKeyboardKey.keyG,
          control: true,
          shift: true,
        ): _findPrevious,
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_findVisible) _buildFindBar(),
              Expanded(
                child: LayoutBuilder(
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
                              color: surface.backgroundColor.withValues(
                                alpha: 0.06,
                              ),
                              border: Border(
                                right: BorderSide(
                                  color: surface.borderColor.withValues(
                                    alpha: 0.05,
                                  ),
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
                                  key: const ValueKey(
                                    'document_editor_line_number_gutter',
                                  ),
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
                                  focusNode: _editorFocusNode,
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
                                    hintText: widget.isReadOnly
                                        ? ''
                                        : widget.hintText,
                                    hintStyle: TextStyle(
                                      fontSize: 14.6,
                                      fontWeight: FontWeight.w500,
                                      height: 1.7,
                                      color: colors.mutedTextColor.withValues(
                                        alpha: 0.72,
                                      ),
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
                ),
              ),
            ],
          ),
          // 中文注释: 桌面有 Ctrl+F，移动端没有——给一个常驻的放大镜按钮作为可发现入口，
          // 查找栏打开时它让位给查找栏自身的关闭按钮。
          if (!_findVisible)
            Positioned(
              top: 2,
              right: 14,
              child: IconButton(
                tooltip: '查找（Ctrl+F）',
                icon: Icon(
                  Icons.search,
                  size: 16,
                  color: colors.mutedTextColor,
                ),
                onPressed: _showFindBar,
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ),
          // 中文注释: 只读资源（非文本资产、渲染预览等）没有任何编辑反馈，容易让用户误以为
          // 应用卡死。给一枚「只读」徽标明确告知此处不可编辑。
          if (widget.isReadOnly && !_findVisible)
            Positioned(
              top: 4,
              left: 8,
              child: Tooltip(
                message: '此资源为只读，不可在此直接编辑。',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.warmColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.warmStrongColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 11,
                        color: colors.warmStrongColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '只读',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: colors.warmStrongColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFindBar() {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final hasQuery = _query.isNotEmpty;
    final countLabel = !hasQuery
        ? ''
        : _matches.isEmpty
        ? '无匹配'
        : '${_currentMatch + 1}/${_matches.length}';
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: colors.lineColor.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _findController,
              focusNode: _findFocusNode,
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 13, color: surface.foregroundColor),
              decoration: InputDecoration(
                isDense: true,
                hintText: '查找内容',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: colors.mutedTextColor,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 15,
                  color: colors.mutedTextColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                suffixText: countLabel,
                suffixStyle: TextStyle(
                  fontSize: 11,
                  color: _matches.isEmpty && hasQuery
                      ? colors.dangerStrongColor
                      : colors.mutedTextColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.lineColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.lineColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.accentColor),
                ),
              ),
              onChanged: (value) {
                _query = value;
                _currentMatch = 0;
                _refreshMatches();
              },
              onSubmitted: (_) => _goMatch(1),
            ),
          ),
          IconButton(
            tooltip: _caseSensitive ? '区分大小写（已开启）' : '区分大小写',
            icon: Text(
              'Aa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _caseSensitive
                    ? colors.accentColor
                    : colors.mutedTextColor,
              ),
            ),
            isSelected: _caseSensitive,
            selectedIcon: Text(
              'Aa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.accentColor,
              ),
            ),
            onPressed: () {
              setState(() => _caseSensitive = !_caseSensitive);
              _refreshMatches();
            },
            visualDensity: VisualDensity.compact,
            splashRadius: 14,
          ),
          IconButton(
            tooltip: '上一个匹配',
            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
            onPressed: _matches.isEmpty ? null : () => _goMatch(-1),
            visualDensity: VisualDensity.compact,
            splashRadius: 14,
          ),
          IconButton(
            tooltip: '下一个匹配',
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            onPressed: _matches.isEmpty ? null : () => _goMatch(1),
            visualDensity: VisualDensity.compact,
            splashRadius: 14,
          ),
          IconButton(
            tooltip: '关闭查找（Esc）',
            icon: const Icon(Icons.close, size: 16),
            onPressed: _hideFindBar,
            visualDensity: VisualDensity.compact,
            splashRadius: 14,
          ),
        ],
      ),
    );
  }

  void _showFindBar() {
    if (!mounted) {
      return;
    }
    setState(() => _findVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _findFocusNode.requestFocus();
      _findController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _findController.text.length,
      );
      _refreshMatches();
    });
  }

  void _hideFindBar() {
    if (!mounted) {
      return;
    }
    // 中文注释: 只隐藏查找栏 UI，保留最近一次的查询与匹配，方便关闭后用 F3 继续跳转。
    setState(() {
      _findVisible = false;
    });
    _editorFocusNode.requestFocus();
  }

  /// F3 / Ctrl+G：有匹配则跳下一个，否则展开查找栏开始新的查找。
  void _findNext() {
    if (_matches.isEmpty) {
      _showFindBar();
      return;
    }
    _goMatch(1);
  }

  /// Shift+F3 / Ctrl+Shift+G：有匹配则跳上一个，否则展开查找栏。
  void _findPrevious() {
    if (_matches.isEmpty) {
      _showFindBar();
      return;
    }
    _goMatch(-1);
  }

  void _handleFindControllerChanged() {
    // 中文注释: 查找栏内容变化已由 onChanged 处理；这里仅用于未来扩展，保持监听对称。
  }

  void _refreshMatches() {
    final text = _controller.text;
    final query = _query;
    final result = <_TextMatch>[];
    if (query.isNotEmpty) {
      // 中文注释: 大小写不敏感时在小写副本上 indexOf；对中英文等长度保持的小写化，
      // 偏移量与原文一致，可直接用于选中/滚动定位（少数会变长的 Unicode 折叠属可接受边界）。
      final hay = _caseSensitive ? text : text.toLowerCase();
      final needle = _caseSensitive ? query : query.toLowerCase();
      var cursor = 0;
      while (cursor <= hay.length) {
        final at = hay.indexOf(needle, cursor);
        if (at < 0) {
          break;
        }
        result.add(_TextMatch(at, at + query.length));
        cursor = at + needle.length;
      }
    }
    _matches = result;
    if (_matches.isEmpty) {
      _currentMatch = -1;
    } else if (_currentMatch < 0 || _currentMatch >= _matches.length) {
      _currentMatch = 0;
    }
    _applySelectionForCurrentMatch();
    if (mounted) {
      setState(() {});
    }
  }

  void _goMatch(int delta) {
    if (_matches.isEmpty) {
      return;
    }
    var next = _currentMatch + delta;
    if (next < 0) {
      next = _matches.length - 1;
    } else if (next >= _matches.length) {
      next = 0;
    }
    _currentMatch = next;
    _applySelectionForCurrentMatch();
    if (mounted) {
      setState(() {});
    }
  }

  void _applySelectionForCurrentMatch() {
    if (_currentMatch < 0 || _currentMatch >= _matches.length) {
      return;
    }
    final match = _matches[_currentMatch];
    _controller.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
    _scrollToOffset(match.start);
  }

  void _scrollToOffset(int characterOffset) {
    // 中文注释: 编辑器用固定 strut（行高确定），按"匹配前的换行数 × 行高"估算滚动位置，
    // 尽量把当前匹配带到视口中部。长行换行会让估算略偏，但已足够定位。
    if (!_scrollController.hasClients) {
      return;
    }
    final text = _controller.text;
    final lineIndex = '\n'
        .allMatches(text.substring(0, characterOffset))
        .length;
    final target = lineIndex * _estimatedLineHeight;
    final viewport = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final desired = target - (viewport / 2) + (_estimatedLineHeight / 2);
    final clamped = desired.clamp(0.0, maxScroll);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _handleControllerChanged() {
    // 中文注释: 正文即时保存(走 TextField.onChanged)，但行号重排 O(N) 用 debounce 延后，
    // 避免长章节每键都重算 TextPainter 卡顿。停顿 150ms 后刷新一次行号。
    // 查找栏隐藏时，正文已变会使旧匹配偏移失效，这里一并作废，避免 F3 跳到错位。
    if (!_findVisible && _matches.isNotEmpty) {
      _matches = const <_TextMatch>[];
      _currentMatch = -1;
    }
    _gutterRefreshTimer?.cancel();
    _gutterRefreshTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {});
      }
    });
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

class _TextMatch {
  const _TextMatch(this.start, this.end);

  final int start;
  final int end;
}
