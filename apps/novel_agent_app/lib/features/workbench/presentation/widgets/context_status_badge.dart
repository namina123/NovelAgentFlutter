import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

class ContextStatusBadge extends StatelessWidget {
  const ContextStatusBadge({super.key, required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 上下文状态徽标独立后，后续压缩策略、token 预算等展示可单独演化。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppPalette.accentSoft,
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.analytics_outlined,
              size: 18,
              color: AppPalette.lineStrong,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                summary,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.lineStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
