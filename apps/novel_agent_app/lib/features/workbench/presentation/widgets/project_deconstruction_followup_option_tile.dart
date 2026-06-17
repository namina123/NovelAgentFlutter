import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/project_deconstruction_followup_option_view_data.dart';

class ProjectDeconstructionFollowupOptionTile extends StatelessWidget {
  const ProjectDeconstructionFollowupOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectDeconstructionFollowupOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentSoftColor.withValues(alpha: 0.18)
              : colors.panelBackground.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colors.accentColor : colors.lineColor,
            width: AppChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.title,
              style: TextStyle(
                color: isSelected ? colors.lineStrongColor : colors.textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              option.description,
              style: TextStyle(
                color: colors.mutedTextColor,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
