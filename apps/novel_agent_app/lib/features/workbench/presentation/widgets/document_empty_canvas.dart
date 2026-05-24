import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

class DocumentEmptyCanvas extends StatelessWidget {
  const DocumentEmptyCanvas({
    super.key,
    this.headline = '打开或新建文档',
    this.message = '从资源区打开文件，或先在会话栏生成新内容后保存到项目目录。',
  });

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 编辑画布占位独立出来，后续换成真正编辑器时只替换这一层。
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 66,
              color: isDark ? theme.colorScheme.primary : AppPalette.lineStrong,
            ),
            const SizedBox(height: 18),
            Text(
              headline,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isDark ? theme.colorScheme.onSurface : AppPalette.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.72)
                    : AppPalette.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
