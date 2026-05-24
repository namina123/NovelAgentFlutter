import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/selector_option_view_data.dart';

class SelectorField extends StatelessWidget {
  const SelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<SelectorOptionViewData> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 右栏选择器拆成独立控件，后续替换成真正下拉或搜索选择器时不动侧栏布局。
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopupMenuButton<String>(
      enabled: options.isNotEmpty,
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) {
        return options
            .map(
              (option) => PopupMenuItem<String>(
                value: option.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (option.note.trim().isNotEmpty)
                      Text(option.note, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.84,
                )
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: AppChrome.surfaceBorderRadius,
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : AppPalette.line,
            width: AppChrome.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 34,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.72)
                        : AppPalette.mutedText,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? theme.colorScheme.onSurface
                        : AppPalette.text,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isDark
                    ? theme.colorScheme.primary
                    : AppPalette.lineStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
