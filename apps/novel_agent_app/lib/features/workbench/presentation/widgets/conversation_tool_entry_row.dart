import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_entry_view_data.dart';
import 'conversation_detail_section.dart';
import 'conversation_entry_palette.dart';

class ConversationToolEntryRow extends StatelessWidget {
  const ConversationToolEntryRow({
    super.key,
    required this.entry,
    required this.palette,
    required this.showDetails,
  });

  final ConversationEntryViewData entry;
  final ConversationEntryPalette palette;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final mutedText = context.novelThemeColors.mutedTextColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: palette.border.withValues(alpha: 0.4),
                      width: AppChrome.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(), size: 12, color: palette.foreground),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: entry.title,
                              style: TextStyle(
                                color: palette.foreground,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (entry.body.trim().isNotEmpty)
                              TextSpan(
                                text: ' · ${entry.body.trim()}',
                                style: TextStyle(
                                  color: entry.isError
                                      ? palette.foreground.withValues(
                                          alpha: 0.88,
                                        )
                                      : mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDetails && entry.detailBody.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ConversationDetailSection(
                  title: entry.detailTitle,
                  summary: entry.detailSummary,
                  body: entry.detailBody,
                  expandedByDefault: false,
                  palette: palette,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _statusIcon() {
    if (entry.isError) {
      return Icons.error_outline_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }
}
