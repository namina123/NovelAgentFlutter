import 'package:flutter/material.dart';

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
    final borderColor = isSelected ? colors.accentColor : colors.lineColor;
    final titleColor = isSelected ? colors.lineStrongColor : colors.textColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardChrome.radius),
          border: Border.all(color: borderColor, width: cardChrome.borderWidth),
          color: isSelected
              ? colors.accentSoftColor.withValues(alpha: 0.92)
              : colors.panelBackground,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.4),
                color: isSelected ? colors.accentColor : Colors.transparent,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colors.mutedTextColor,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
