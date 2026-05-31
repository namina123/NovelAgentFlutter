import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/theme_settings_view_data.dart';

class ThemeOptionTile extends StatelessWidget {
  const ThemeOptionTile({super.key, required this.option, required this.onTap});

  final ThemeOptionViewData option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final borderColor = option.isSelected
        ? surface.highlightBorderColor
        : surface.borderColor;
    final backgroundColor = option.isSelected
        ? surface.highlightBackgroundColor.withValues(alpha: 0.92)
        : surface.backgroundColor.withValues(alpha: 0.76);
    final titleColor = option.isSelected
        ? surface.highlightForegroundColor
        : surface.foregroundColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: surface.borderWidth),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemeSwatchStrip(swatches: option.previewSwatches),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: surface.backgroundColor.withValues(
                              alpha: 0.68,
                            ),
                            border: Border.all(
                              color: surface.borderColor,
                              width: surface.borderWidth,
                            ),
                          ),
                          child: Text(
                            option.badgeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: surface.mutedForegroundColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: surface.mutedForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                option.isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: option.isSelected
                    ? surface.highlightBorderColor
                    : surface.mutedForegroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatchStrip extends StatelessWidget {
  const _ThemeSwatchStrip({required this.swatches});

  final List<Color> swatches;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        children: [
          for (final swatch in swatches) ...[
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: swatch,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            if (swatch != swatches.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
