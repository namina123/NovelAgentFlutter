import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_pending_input_preview_view_data.dart';
import 'conversation_panel_style.dart';

class ConversationPendingInputPreviewPanel extends StatelessWidget {
  const ConversationPendingInputPreviewPanel({
    super.key,
    required this.viewData,
  });

  final ConversationPendingInputPreviewViewData viewData;

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final panel = context.novelThemeSurfaces.inputDock;
    return Container(
      width: double.infinity,
      padding: style.bandPadding,
      decoration: BoxDecoration(
        color: style.bandBackgroundColor,
        border: Border.all(
          color: style.bandBorderColor,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule_send_outlined,
                size: 15,
                color: style.accentBandForegroundColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '待发送输入',
                  style: TextStyle(
                    color: style.accentBandForegroundColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${viewData.lineCount} 行 · ${viewData.characterCount} 字符',
                style: TextStyle(
                  color: panel.mutedForegroundColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            viewData.previewText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: panel.foregroundColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
