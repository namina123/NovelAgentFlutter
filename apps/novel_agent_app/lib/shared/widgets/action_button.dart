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
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;
  final ActionButtonTone tone;
  final bool compact;
  final int labelMaxLines;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final chrome = context.novelButtonChrome;
    final foreground = _foregroundColor(colors);
    final border = _borderColor(colors);
    final background = _backgroundColor(colors);
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(
          0,
          compact ? chrome.compactMinHeight : chrome.regularMinHeight,
        ),
        padding: compact ? chrome.compactPadding : chrome.regularPadding,
        foregroundColor: foreground,
        side: BorderSide(color: border, width: chrome.borderWidth),
        backgroundColor: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chrome.radius),
          side: BorderSide(color: border, width: chrome.borderWidth),
        ),
        textStyle: TextStyle(
          fontSize: compact ? (emphasized ? 11.8 : 11.5) : 13.5,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          letterSpacing: 0,
        ),
        elevation: emphasized ? 0 : 0,
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
    switch (tone) {
      case ActionButtonTone.accent:
        return emphasized
            ? themeColors.accentColor.withValues(alpha: 0.18)
            : themeColors.accentSoftColor.withValues(alpha: 0.68);
      case ActionButtonTone.warm:
        return themeColors.warmColor.withValues(alpha: 0.68);
      case ActionButtonTone.neutral:
        return themeColors.panelBackground.withValues(alpha: 0.16);
      case ActionButtonTone.danger:
        return themeColors.dangerSoftColor.withValues(alpha: 0.68);
    }
  }

  Color _foregroundColor(ThemeColorTokens themeColors) {
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
    switch (tone) {
      case ActionButtonTone.accent:
        return emphasized
            ? themeColors.accentColor.withValues(alpha: 0.46)
            : themeColors.lineColor.withValues(alpha: 0.82);
      case ActionButtonTone.warm:
        return themeColors.warmStrongColor.withValues(alpha: 0.58);
      case ActionButtonTone.neutral:
        return themeColors.lineColor.withValues(alpha: 0.72);
      case ActionButtonTone.danger:
        return themeColors.dangerStrongColor.withValues(alpha: 0.54);
    }
  }
}

enum ActionButtonTone { accent, warm, neutral, danger }
