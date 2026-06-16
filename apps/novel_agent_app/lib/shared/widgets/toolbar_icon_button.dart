import 'package:flutter/material.dart';

import '../../app/theme/theme_color_tokens.dart';
import '../theme/novel_theme_context.dart';

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = ToolbarIconTone.neutral,
    this.dense = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final ToolbarIconTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工具按钮整体改得更像 IDE 命令按钮，保留语义色但降低“实心按钮”感。
    final colors = context.novelThemeColors;
    final chrome = context.novelToolbarChrome;
    final isEnabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: isEnabled
              ? _foregroundColor(colors)
              : _foregroundColor(colors).withValues(alpha: 0.38),
          backgroundColor: isEnabled
              ? _backgroundColor(colors)
              : _backgroundColor(colors).withValues(alpha: 0.55),
          minimumSize: Size.square(chrome.buttonSize),
          padding: chrome.padding,
          visualDensity: dense ? VisualDensity.compact : null,
          tapTargetSize: dense
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(chrome.radius),
            side: BorderSide(
              color: _borderColor(colors),
              width: chrome.borderWidth,
            ),
          ),
        ),
        icon: Icon(icon, size: chrome.iconSize),
      ),
    );
  }

  Color _backgroundColor(ThemeColorTokens themeColors) {
    // 中文注释: 编辑器工具按钮保持近乎透明，只在 hover/selected 时靠边界和语义色区分。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return themeColors.panelBackground.withValues(alpha: 0.04);
      case ToolbarIconTone.accent:
        return themeColors.accentSoftColor.withValues(alpha: 0.1);
      case ToolbarIconTone.warm:
        return themeColors.warmColor.withValues(alpha: 0.12);
    }
  }

  Color _foregroundColor(ThemeColorTokens themeColors) {
    // 中文注释: 图标颜色按语义设置，帮助用户快速辨认主辅动作。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return themeColors.textColor;
      case ToolbarIconTone.accent:
        return themeColors.lineStrongColor;
      case ToolbarIconTone.warm:
        return themeColors.warmStrongColor;
    }
  }

  Color _borderColor(ThemeColorTokens themeColors) {
    // 中文注释: 边框只做轻提示，避免工具条继续像一排按钮卡片。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return themeColors.lineColor.withValues(alpha: 0.18);
      case ToolbarIconTone.accent:
        return themeColors.lineColor.withValues(alpha: 0.22);
      case ToolbarIconTone.warm:
        return themeColors.warmStrongColor.withValues(alpha: 0.24);
    }
  }
}

enum ToolbarIconTone { neutral, accent, warm }
