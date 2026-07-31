import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

/// 对话输入框。输入 `/` 时在输入框上方弹出斜杠指令自动补全浮层，
/// 支持方向键导航、Enter/Tab 选中、Esc 关闭。选中后回填 `/命令名 ` 以便继续输参数。
class ConversationComposerTextField extends StatefulWidget {
  const ConversationComposerTextField({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.hintText,
    List<ConversationCommandSuggestion>? suggestions,
  }) : _suggestions = suggestions;

  final TextEditingController controller;
  final ScrollController scrollController;
  final String hintText;

  final List<ConversationCommandSuggestion>? _suggestions;

  @override
  State<ConversationComposerTextField> createState() =>
      _ConversationComposerTextFieldState();
}

class _ConversationComposerTextFieldState
    extends State<ConversationComposerTextField> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final FocusNode _focusNode = FocusNode();
  List<ConversationCommandSuggestion> _matches =
      const <ConversationCommandSuggestion>[];
  int _selectedIndex = 0;

  List<ConversationCommandSuggestion> get _suggestions =>
      widget._suggestions ?? builtinConversationCommandSuggestions();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.onKeyEvent = _onKeyEvent;
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant ConversationComposerTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // 中文注释: 输入框失焦时收起补全浮层，避免浮层在无焦点时残留。
    if (!_focusNode.hasFocus && _overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final trimmed = text.trimLeft();
    if (!trimmed.startsWith('/')) {
      _hideOverlay();
      return;
    }
    final afterSlash = trimmed.substring(1);
    // 中文注释: 只有还在输命令名（/ 后无空格）时才补全；一旦进入参数输入就收起浮层。
    if (afterSlash.contains(RegExp(r'\s'))) {
      _hideOverlay();
      return;
    }
    final matches = _suggestions
        .where((suggestion) => suggestion.name.startsWith(afterSlash))
        .toList(growable: false);
    if (matches.isEmpty) {
      _hideOverlay();
      return;
    }
    setState(() {
      _matches = matches;
      _selectedIndex = 0;
    });
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _hideOverlay() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _pick(ConversationCommandSuggestion suggestion) {
    // 中文注释: 选中后回填 "/命令名 "（带尾空格），把光标移到末尾方便继续输参数。
    final replacement = '/${suggestion.name} ';
    widget.controller.value = TextEditingValue(
      text: replacement,
      selection: TextSelection.collapsed(offset: replacement.length),
    );
    _hideOverlay();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!_overlayController.isShowing || _matches.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % _matches.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1) % _matches.length;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _pick(_matches[_selectedIndex]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _hideOverlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return SizedBox(
      height: 92,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (BuildContext context) =>
              _buildSuggestionOverlay(context),
          child: Scrollbar(
            controller: widget.scrollController,
            thumbVisibility: false,
            child: TextField(
              controller: widget.controller,
              scrollController: widget.scrollController,
              focusNode: _focusNode,
              scrollPhysics: const ClampingScrollPhysics(),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: null,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                color: surface.foregroundColor,
                fontSize: 13,
                height: 1.56,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: colors.accentColor,
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: TextStyle(
                  color: colors.mutedTextColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionOverlay(BuildContext context) {
    // 中文注释: 浮层贴在输入框左上角、向上展开（followerAnchor bottomLeft 对齐 target topLeft）。
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return CompositedTransformFollower(
      link: _layerLink,
      targetAnchor: Alignment.topLeft,
      followerAnchor: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 4),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          color: surface.backgroundColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                final selected = index == _selectedIndex;
                return InkWell(
                  onTap: () => _pick(match),
                  child: Container(
                    color: selected
                        ? colors.accentColor.withValues(alpha: 0.16)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          '/${match.name}',
                          style: TextStyle(
                            color: surface.foregroundColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (match.argHint.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 6),
                          Text(
                            match.argHint,
                            style: TextStyle(
                              color: colors.mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            match.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.mutedTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
