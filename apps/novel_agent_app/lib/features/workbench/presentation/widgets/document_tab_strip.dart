import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/workbench_view_data.dart';

class DocumentTabStrip extends StatelessWidget {
  const DocumentTabStrip({super.key, required this.documents});

  final List<DocumentTabViewData> documents;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档标签独立成组件，后续如果切换为可关闭标签或滚动标签条时不动外层页面。
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: documents.map((document) {
        final background = document.isActive
            ? AppPalette.accentSoft
            : Colors.white.withValues(alpha: 0.72);
        final foreground = document.isActive
            ? AppPalette.lineStrong
            : AppPalette.text;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppChrome.surfaceBorderRadius,
            border: Border.all(color: AppPalette.line, width: AppChrome.borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              document.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: document.isActive
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
