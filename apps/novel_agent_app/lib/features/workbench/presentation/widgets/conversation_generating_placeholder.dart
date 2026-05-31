import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class ConversationGeneratingPlaceholder extends StatelessWidget {
  const ConversationGeneratingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.warmColor.withValues(alpha: 0.56),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: colors.warmStrongColor.withValues(alpha: 0.42),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '智能体正在处理当前请求...',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
