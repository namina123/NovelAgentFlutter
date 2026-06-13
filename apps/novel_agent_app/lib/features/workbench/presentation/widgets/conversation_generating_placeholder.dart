import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class ConversationGeneratingPlaceholder extends StatelessWidget {
  const ConversationGeneratingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.92),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.92),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: colors.accentSoftColor.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(
              Icons.stream_rounded,
              size: 13,
              color: colors.accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '智能体正在生成回复',
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '输出会随着工具执行和推理进度持续写入当前会话。',
                  style: TextStyle(
                    color: colors.mutedTextColor,
                    fontSize: 10.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
