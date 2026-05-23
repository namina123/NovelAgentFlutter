import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/conversation_entry_view_data.dart';
import 'conversation_entry_tile.dart';

class ConversationTimeline extends StatelessWidget {
  const ConversationTimeline({
    super.key,
    required this.entries,
    required this.isGenerating,
  });

  final List<ConversationEntryViewData> entries;
  final bool isGenerating;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话时间线只关心消息轨迹展示，不承担选项决策和会话历史切换职责。
    if (entries.isEmpty && !isGenerating) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '会话轨迹',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (entries.isNotEmpty)
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ConversationEntryTile(entry: entry),
            ),
          ),
        if (isGenerating)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFD9),
              borderRadius: AppChrome.surfaceBorderRadius,
              border: Border.all(
                color: const Color(0xFFD8C790),
                width: AppChrome.borderWidth,
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '智能体正在继续处理当前请求...',
                    style: TextStyle(
                      color: AppPalette.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
