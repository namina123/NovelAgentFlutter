import 'package:flutter/material.dart';

import '../../app/theme/theme_color_tokens.dart';
import '../theme/novel_theme_context.dart';

/// 一次性反馈的严重程度，决定 SnackBar 的底色与前景色。
enum AppFeedbackSeverity {
  /// 常规提示（如「已复制」），使用主题强对比的中性底色。
  info,

  /// 成功（如「已保存」），使用强调色。
  success,

  /// 需要注意但不阻塞（如降级提示）。
  warning,

  /// 失败/错误，使用危险色。
  error,
}

/// 应用统一的瞬时反馈入口。
///
/// 全应用过去没有任何 SnackBar / Toast：用户点击「保存」「复制」「删除」后往往得不到
/// 明确回执，只能去状态条碰运气。本类收口为一个主题化的浮动 SnackBar 助手，供任意
/// 拥有 [BuildContext] 的调用点使用（控制器无 context，仍走各自的 generationStatus）。
class AppFeedback {
  const AppFeedback._();

  /// 显示一条浮动反馈。同一时刻只保留最新一条（先隐藏当前再展示新的）。
  static void show(
    BuildContext context,
    String message, {
    AppFeedbackSeverity severity = AppFeedbackSeverity.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    final colors = context.novelThemeColors;
    final (background, foreground) = _palette(severity, colors);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: foreground, fontSize: 13, height: 1.35),
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          backgroundColor: background,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          showCloseIcon: true,
          closeIconColor: foreground.withValues(alpha: 0.85),
        ),
      );
  }

  static (Color, Color) _palette(
    AppFeedbackSeverity severity,
    ThemeColorTokens colors,
  ) {
    switch (severity) {
      case AppFeedbackSeverity.info:
        // 中文注释: info 用正文色作底、反色作字，亮暗主题下都是最高对比的中性提示。
        return (colors.textColor, colors.inverseTextColor);
      case AppFeedbackSeverity.success:
        return (colors.accentColor, Colors.white);
      case AppFeedbackSeverity.warning:
        return (colors.warmStrongColor, Colors.white);
      case AppFeedbackSeverity.error:
        return (colors.dangerStrongColor, Colors.white);
    }
  }
}
