import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/theme_color_tokens.dart';
import '../../../shared/theme/novel_theme_context.dart';
import '../application/command_palette_controller.dart';
import '../domain/command.dart';

/// 弹出命令面板。
///
/// 返回被选中执行的 [AppCommand]（便于测试断言与上层日志）；用户取消（Esc /
/// 点击遮罩）返回 null。每次打开都会新建一个 [CommandPaletteController]，
/// 因此面板状态彼此隔离。
Future<AppCommand?> showCommandPalette(
  BuildContext context, {
  required CommandPaletteController controller,
}) {
  controller.open();
  return showDialog<AppCommand>(
    context: context,
    // 中文注释: 半透明遮罩，比默认纯黑更柔和，仍能压暗背后的创作台。
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (dialogContext) => CommandPaletteDialog(controller: controller),
  );
}

/// 命令面板对话框：顶部搜索框 + 命中列表 + 底部快捷键提示。
///
/// 键盘交互（参照 [ConversationComposerTextField] 的 FocusNode.onKeyEvent 模式）：
/// 上下方向键移动选中、Enter 执行、Esc 关闭。搜索框为单行，因此方向键不会与
/// 光标移动冲突；onKeyEvent 直接拦截这些键并返回 handled。
class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key, required this.controller});

  final CommandPaletteController controller;

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  late final TextEditingController _textController;
  final FocusNode _fieldFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  /// 单条结果行预估高度（含 padding）。用于键盘移动后自动滚动到选中项。
  static const double _itemExtent = 52;

  /// 防止 Enter(onKeyEvent) 与 IME「前往」(onSubmitted) 双路径重复执行同一命令。
  bool _invoked = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _fieldFocusNode.onKeyEvent = _handleKeyEvent;
    widget.controller.addListener(_ensureSelectedVisible);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_ensureSelectedVisible);
    _textController.dispose();
    _fieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // 中文注释: 只在按下与按住重复时响应，放行抬起事件，避免一次方向键触发两次。
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final controller = widget.controller;
    if (key == LogicalKeyboardKey.arrowDown) {
      controller.moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      controller.moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      controller.selectIndex(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      controller.selectIndex(controller.resultCount - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      controller.moveSelection(-_pageSize());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      controller.moveSelection(_pageSize());
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).maybePop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _invokeSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 按视口高度估算一页的条目数，用于 PageUp / PageDown 翻页。
  int _pageSize() {
    if (!_scrollController.hasClients) return 7;
    final viewport = _scrollController.position.viewportDimension;
    final size = (viewport / _itemExtent).floor();
    return size < 1 ? 1 : size;
  }

  void _invokeSelected() {
    if (_invoked) return;
    final command = widget.controller.selectedCommand;
    if (command == null) return;
    _invoked = true;
    // 中文注释: 先关面板再执行，确保命令自身弹出的二级界面（如新建文件）叠在干净栈上。
    Navigator.of(context).pop(command);
    command.invoke();
  }

  void _ensureSelectedVisible() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final index = widget.controller.selectedIndex;
      final viewport = _scrollController.position.viewportDimension;
      final target = index * _itemExtent;
      final current = _scrollController.offset;
      if (target < current) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      } else if (target + _itemExtent > current + viewport) {
        _scrollController.animateTo(
          target + _itemExtent - viewport,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final panelSurface = context.novelThemeSurfaces.panel;
    // 中文注释: 移动端软键盘弹出时压低面板上限，配合 topCenter 对齐把命中区与底部
    // 提示始终留在键盘上方，避免被遮挡。
    final viewInsetBottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = (460 - viewInsetBottom).clamp(180.0, 460.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Material(
          color: panelSurface.backgroundColor,
          elevation: 16,
          borderRadius: BorderRadius.circular(panelSurface.radius),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSearchField(colors),
              Divider(height: 1, thickness: 1, color: colors.lineColor),
              Flexible(
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildResults(colors),
                        ),
                        _buildFooter(colors),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeColorTokens colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: colors.mutedTextColor),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _fieldFocusNode,
              autofocus: true,
              // 中文注释: 用「前往」动作键，让移动端 IME 也能一键执行首个命中；
              // 桌面 Enter 仍由 _fieldFocusNode.onKeyEvent 拦截处理（返回 handled 会
              // 阻止 onSubmitted 触发，二者互斥；_invoked 再兜底防重复执行）。
              textInputAction: TextInputAction.go,
              style: TextStyle(color: colors.textColor, fontSize: 15),
              decoration: InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '输入命令名或关键词…',
                hintStyle: TextStyle(color: colors.mutedTextColor),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: widget.controller.setQuery,
              onSubmitted: (_) => _invokeSelected(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeColorTokens colors) {
    final results = widget.controller.results;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '没有匹配的命令',
                style: TextStyle(color: colors.textColor, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '试试「保存」「新建」「设置」「停止生成」等关键词',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedTextColor, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }
    final selectedIndex = widget.controller.selectedIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6),
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final scored = results[index];
        final selected = index == selectedIndex;
        return _CommandTile(
          command: scored.command,
          selected: selected,
          colors: colors,
          isDark: isDark,
          onTap: () {
            widget.controller.selectIndex(index);
            _invokeSelected();
          },
          onHoverChange: (hovering) {
            if (hovering) widget.controller.selectIndex(index);
          },
        );
      },
    );
  }

  Widget _buildFooter(ThemeColorTokens colors) {
    final count = widget.controller.resultCount;
    final position = count > 0 ? '${widget.controller.selectedIndex + 1}/$count' : '无结果';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: colors.sidebarBackground.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: colors.lineColor, width: 1)),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: colors.mutedTextColor, fontSize: 11),
        child: Row(
          children: [
            _KeyHint(text: '↑↓', colors: colors),
            const SizedBox(width: 4),
            const Text('选择'),
            const SizedBox(width: 12),
            _KeyHint(text: 'Enter', colors: colors),
            const SizedBox(width: 4),
            const Text('执行'),
            const SizedBox(width: 12),
            _KeyHint(text: 'Esc', colors: colors),
            const SizedBox(width: 4),
            const Text('关闭'),
            const Spacer(),
            Text(position),
          ],
        ),
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.command,
    required this.selected,
    required this.colors,
    required this.isDark,
    required this.onTap,
    required this.onHoverChange,
  });

  final AppCommand command;
  final bool selected;
  final ThemeColorTokens colors;
  final bool isDark;
  final VoidCallback onTap;
  final void Function(bool hovering) onHoverChange;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 亮色沿用 accentSoftColor（与创作台各高亮一致）；暗色下 accentSoftColor
    // 与面板底色过近难以分辨，改用 accentColor 半透明叠加，制造可辨的亮度阶。
    final background = selected
        ? (isDark
            ? colors.accentColor.withValues(alpha: 0.22)
            : colors.accentSoftColor)
        : Colors.transparent;
    return InkWell(
      onTap: onTap,
      onHover: onHoverChange,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          border: Border(
            left: BorderSide(
              color: selected ? colors.accentColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _categoryIcon(command.category),
              size: 18,
              color: selected ? colors.accentColor : colors.mutedTextColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    command.title,
                    style: TextStyle(
                      color: colors.textColor,
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (command.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      command.subtitle!,
                      style: TextStyle(
                        color: colors.mutedTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (command.shortcutLabel != null) ...[
              const SizedBox(width: 8),
              _KeyHint(text: command.shortcutLabel!, colors: colors),
            ],
            const SizedBox(width: 8),
            Text(
              command.category.label,
              style: TextStyle(color: colors.mutedTextColor, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  const _KeyHint({required this.text, required this.colors});

  final String text;
  final ThemeColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.lineColor, width: 1),
      ),
      child: Text(text, style: TextStyle(color: colors.mutedTextColor, fontSize: 10)),
    );
  }
}

IconData _categoryIcon(CommandCategory category) {
  switch (category) {
    case CommandCategory.navigation:
      return Icons.alt_route;
    case CommandCategory.document:
      return Icons.description_outlined;
    case CommandCategory.view:
      return Icons.view_sidebar_outlined;
    case CommandCategory.operations:
      return Icons.bolt_outlined;
    case CommandCategory.theme:
      return Icons.palette_outlined;
  }
}
