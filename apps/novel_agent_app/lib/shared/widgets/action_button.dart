import 'package:flutter/material.dart';

import '../../app/theme/theme_color_tokens.dart';
import '../theme/novel_theme_context.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
    this.tone = ActionButtonTone.accent,
    this.compact = false,
    this.labelMaxLines = 1,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;
  final ActionButtonTone tone;
  final bool compact;
  final int labelMaxLines;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 统一业务按钮的视觉层级，让不同页面的动作密度一致，而不是每页自造按钮风格。
    final colors = context.novelThemeColors;
    final chrome = context.novelButtonChrome;
    final foreground = _foregroundColor(colors);
    final border = _borderColor(colors);
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(
          0,
          compact ? chrome.compactMinHeight : chrome.regularMinHeight,
        ),
        padding: compact ? chrome.compactPadding : chrome.regularPadding,
        foregroundColor: foreground,
        side: BorderSide(color: border, width: chrome.borderWidth),
        backgroundColor: _backgroundColor(colors),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chrome.radius),
          side: BorderSide(color: border, width: chrome.borderWidth),
        ),
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? chrome.compactIconSize : chrome.regularIconSize,
              color: foreground,
            ),
            SizedBox(width: compact ? 4 : 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: labelMaxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              softWrap: labelMaxLines > 1,
            ),
          ),
        ],
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Color _backgroundColor(ThemeColorTokens themeColors) {
    // 中文注释: 按钮底色按语义分层，保证工具型按钮和重点动作按钮有清晰区分。
    switch (tone) {
      case ActionButtonTone.accent:
        return themeColors.accentSoftColor;
      case ActionButtonTone.warm:
        return themeColors.warmColor;
      case ActionButtonTone.neutral:
        return Colors.transparent;
      case ActionButtonTone.danger:
        return themeColors.dangerSoftColor;
    }
  }

  Color _foregroundColor(ThemeColorTokens themeColors) {
    // 中文注释: 文字和图标颜色与按钮语义保持一致，避免用同一套颜色覆盖所有状态。
    switch (tone) {
      case ActionButtonTone.accent:
        return themeColors.lineStrongColor;
      case ActionButtonTone.warm:
        return themeColors.warmStrongColor;
      case ActionButtonTone.neutral:
        return themeColors.textColor;
      case ActionButtonTone.danger:
        return themeColors.dangerStrongColor;
    }
  }

  Color _borderColor(ThemeColorTokens themeColors) {
    // 中文注释: 边框颜色跟随按钮语义变化，用来提升大面积浅色界面中的层次感。
    switch (tone) {
      case ActionButtonTone.accent:
        return themeColors.lineColor;
      case ActionButtonTone.warm:
        return themeColors.warmStrongColor.withValues(alpha: 0.7);
      case ActionButtonTone.neutral:
        return themeColors.lineColor;
      case ActionButtonTone.danger:
        return themeColors.dangerStrongColor.withValues(alpha: 0.62);
    }
  }
}

enum ActionButtonTone { accent, warm, neutral, danger }
