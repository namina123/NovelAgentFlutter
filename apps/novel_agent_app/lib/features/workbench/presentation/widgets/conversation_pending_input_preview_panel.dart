import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_pending_input_preview_view_data.dart';
import 'conversation_panel_style.dart';

class ConversationPendingInputPreviewPanel extends StatelessWidget {
  const ConversationPendingInputPreviewPanel({
    super.key,
    required this.viewData,
    this.onClear,
  });

  final ConversationPendingInputPreviewViewData viewData;

  /// 清空待发送草稿。生成中文本框仍可编辑，这里补一个就近的「清空」让用户快速丢弃误排队的草稿。
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final panel = context.novelThemeSurfaces.inputDock;
    return Container(
      width: double.infinity,
      padding: style.inset(left: -1, right: -1, top: -1, bottom: -1),
      decoration: BoxDecoration(
        color: style.bandBackgroundColor.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(
            color: style.bandBorderColor.withValues(alpha: 0.42),
            width: AppChrome.borderWidth,
          ),
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
                    fontSize: style.metaFontSize,
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
              if (onClear != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    foregroundColor: panel.mutedForegroundColor,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    textStyle: TextStyle(
                      fontSize: style.metaFontSize - 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('清空'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            viewData.previewText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: panel.foregroundColor,
              fontSize: style.bodyFontSize,
              height: style.bodyLineHeight,
            ),
          ),
        ],
      ),
    );
  }
}
