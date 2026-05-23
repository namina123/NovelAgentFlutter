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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_note_rounded,
              size: 66,
              color: AppPalette.lineStrong,
            ),
            const SizedBox(height: 18),
            Text(
              headline,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppPalette.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppPalette.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
