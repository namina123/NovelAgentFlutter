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
    final itemCount = entries.length + (isGenerating ? 1 : 0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Scrollbar(
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index < entries.length) {
              return ConversationEntryTile(entry: entries[index]);
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '智能体正在处理当前请求...',
                      style: TextStyle(
                        color: AppPalette.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
