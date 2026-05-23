import 'package:flutter/material.dart';

import '../../app/theme/app_chrome.dart';
import '../../app/theme/app_palette.dart';

class ToolbarIconButton extends StatelessWidget {
  const ToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone = ToolbarIconTone.neutral,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final ToolbarIconTone tone;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 顶部工具按钮统一收敛到同一组件，避免头部小按钮在多个页面里各长各的样子。
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: _foregroundColor(),
          backgroundColor: _backgroundColor(),
          minimumSize: const Size(34, 34),
          padding: const EdgeInsets.all(6),
          shape: AppChrome.controlShape(sideColor: _borderColor()),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }

  Color _backgroundColor() {
    // 中文注释: 工具按钮底色保持克制，但为主题、危险等动作留出语义色空间。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return AppPalette.panel;
      case ToolbarIconTone.accent:
        return AppPalette.accentSoft;
      case ToolbarIconTone.warm:
        return AppPalette.warm;
    }
  }

  Color _foregroundColor() {
    // 中文注释: 图标颜色按语义设置，帮助用户快速辨认主辅动作。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return AppPalette.text;
      case ToolbarIconTone.accent:
        return AppPalette.lineStrong;
      case ToolbarIconTone.warm:
        return AppPalette.warmStrong;
    }
  }

  Color _borderColor() {
    // 中文注释: 边框颜色和工具按钮语义配套，避免大面积浅色背景下按钮边界模糊。
    switch (tone) {
      case ToolbarIconTone.neutral:
        return AppPalette.line;
      case ToolbarIconTone.accent:
        return AppPalette.line;
      case ToolbarIconTone.warm:
        return const Color(0xFFD9A15A);
    }
  }
}

enum ToolbarIconTone { neutral, accent, warm }
