import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class ProjectSelectionOptionCard extends StatelessWidget {
  const ProjectSelectionOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final cardChrome = context.novelCardChrome;
    final borderColor = isSelected
        ? colors.accentColor.withValues(alpha: 0.84)
        : colors.lineColor.withValues(alpha: 0.68);
    final titleColor = isSelected ? colors.lineStrongColor : colors.textColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(cardChrome.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardChrome.radius),
          border: Border.all(color: borderColor, width: cardChrome.borderWidth),
          color: isSelected
              ? colors.accentSoftColor.withValues(alpha: 0.18)
              : colors.inputBackground.withValues(alpha: 0.64),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor,
                  width: AppChrome.borderWidth,
                ),
                color: isSelected
                    ? colors.accentSoftColor.withValues(alpha: 0.42)
                    : colors.panelBackground.withValues(alpha: 0.56),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.add_rounded,
                size: 13,
                color: isSelected ? colors.accentColor : colors.mutedTextColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.mutedTextColor,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentSoftColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '当前',
                  style: TextStyle(
                    color: colors.lineStrongColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
