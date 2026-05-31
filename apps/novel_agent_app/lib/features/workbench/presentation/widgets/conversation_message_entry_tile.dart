import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_entry_view_data.dart';
import 'conversation_detail_section.dart';
import 'conversation_entry_palette.dart';

class ConversationMessageEntryTile extends StatelessWidget {
  const ConversationMessageEntryTile({
    super.key,
    required this.entry,
    required this.palette,
  });

  final ConversationEntryViewData entry;
  final ConversationEntryPalette palette;

  @override
  Widget build(BuildContext context) {
    final bodyTextColor = entry.isError
        ? palette.foreground
        : context.novelThemeColors.textColor;
    final useFastBodyRendering = entry.id == 'assistant_streaming';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(color: palette.border, width: AppChrome.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(palette.icon, size: 16, color: palette.foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (entry.body.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _BodyText(
              text: entry.body,
              color: bodyTextColor,
              useFastRendering: useFastBodyRendering,
            ),
          ],
          if (entry.detailBody.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ConversationDetailSection(
              title: entry.detailTitle,
              summary: entry.detailSummary,
              body: entry.detailBody,
              expandedByDefault: entry.detailExpandedByDefault,
              palette: palette,
            ),
          ],
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText({
    required this.text,
    required this.color,
    required this.useFastRendering,
  });

  final String text;
  final Color color;
  final bool useFastRendering;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontSize: 12, height: 1.4);
    if (useFastRendering) {
      return Text(text, style: style);
    }
    return SelectableText(text, style: style);
  }
}
