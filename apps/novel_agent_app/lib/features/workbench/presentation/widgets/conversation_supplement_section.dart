import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

class ConversationSupplementSection extends StatelessWidget {
  const ConversationSupplementSection({
    super.key,
    required this.child,
    this.title = '补充说明',
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.52),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.mutedTextColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
