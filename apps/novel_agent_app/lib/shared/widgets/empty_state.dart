import 'package:flutter/material.dart';

import '../theme/novel_theme_context.dart';

/// 应用统一的空态组件。
///
/// 此前各页各自堆一个 `Text(...)`：有的带图标有的没有、有的用 mutedForeground 有的用
/// 默认正文色、多数没有引导动作。本组件收口为一个主题化（mutedTextColor）的空态，
/// 可选图标 / 标题 / 提示 / 行动按钮，逐步迁移各空态站点以统一观感与可达性。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.message,
    this.hint,
    this.action,
    this.emphasized = false,
  });

  /// 顶部图标；为空时不渲染（适合纯文案空态）。
  final IconData? icon;

  /// 主标题（一行，居中）。
  final String message;

  /// 次级提示；解释为何为空或下一步该做什么。
  final String? hint;

  /// 可选的行动入口（如「新建」「去设置」），让空态可被直接推进而不是只读一句。
  final Widget? action;

  /// 强调态：标题用正文色而非次级色（用于"这里就是空的、不是加载中"的明确告知）。
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final titleColor = emphasized ? colors.textColor : colors.mutedTextColor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 30,
                color: colors.mutedTextColor.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: colors.mutedTextColor.withValues(alpha: 0.85),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 14),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
