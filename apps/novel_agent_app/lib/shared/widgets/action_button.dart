import 'package:flutter/material.dart';

import '../../app/theme/app_chrome.dart';
import '../../app/theme/app_palette.dart';

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
    final foreground = _foregroundColor();
    final border = _borderColor();
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, compact ? 34 : 42),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 6 : 9,
        ),
        foregroundColor: foreground,
        side: BorderSide(color: border, width: AppChrome.borderWidth),
        backgroundColor: _backgroundColor(),
        shape: AppChrome.controlShape(sideColor: border),
        textStyle: TextStyle(
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 14 : 18, color: foreground),
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

  Color _backgroundColor() {
    // 中文注释: 按钮底色按语义分层，保证工具型按钮和重点动作按钮有清晰区分。
    switch (tone) {
      case ActionButtonTone.accent:
        return AppPalette.accentSoft;
      case ActionButtonTone.warm:
        return AppPalette.warm;
      case ActionButtonTone.neutral:
        return Colors.transparent;
      case ActionButtonTone.danger:
        return AppPalette.dangerSoft;
    }
  }

  Color _foregroundColor() {
    // 中文注释: 文字和图标颜色与按钮语义保持一致，避免用同一套颜色覆盖所有状态。
    switch (tone) {
      case ActionButtonTone.accent:
        return AppPalette.lineStrong;
      case ActionButtonTone.warm:
        return AppPalette.warmStrong;
      case ActionButtonTone.neutral:
        return AppPalette.text;
      case ActionButtonTone.danger:
        return const Color(0xFFAF3E30);
    }
  }

  Color _borderColor() {
    // 中文注释: 边框颜色跟随按钮语义变化，用来提升大面积浅色界面中的层次感。
    switch (tone) {
      case ActionButtonTone.accent:
        return AppPalette.line;
      case ActionButtonTone.warm:
        return const Color(0xFFD9A15A);
      case ActionButtonTone.neutral:
        return AppPalette.line;
      case ActionButtonTone.danger:
        return const Color(0xFFE19B92);
    }
  }
}

enum ActionButtonTone { accent, warm, neutral, danger }
