import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/selector_option_view_data.dart';

class SelectorField extends StatelessWidget {
  const SelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.showLabel = true,
  });

  final String label;
  final String value;
  final List<SelectorOptionViewData> options;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 选择器继续向 IDE 侧栏字段靠拢，弱化表单输入框感。
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    final labelStyle = TextStyle(
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
      color: colors.mutedTextColor,
    );
    final labelWidth = showLabel
        ? _labelWidth(context, label, labelStyle)
        : 0.0;
    return PopupMenuButton<String>(
      enabled: enabled && options.isNotEmpty,
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
          color: surface.backgroundColor.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(
              color: surface.borderColor.withValues(alpha: 0.34),
              width: AppChrome.borderWidth,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showLabel)
                SizedBox(
                  width: labelWidth,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: labelStyle,
                  ),
                ),
              if (showLabel) const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textColor,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: enabled && options.isNotEmpty
                    ? colors.lineStrongColor
                    : colors.mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _labelWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width.ceilToDouble() + 2;
  }
}
