import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/workbench_view_data.dart';
import 'primary_action_list.dart';

class ConversationEmptyStatePanel extends StatelessWidget {
  const ConversationEmptyStatePanel({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
    required this.actionHandler,
    required this.onSettingsRequested,
  });

  final String title;
  final String description;
  final List<PrimaryActionViewData> actions;
  final ConversationActionHandler actionHandler;
  final VoidCallback onSettingsRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 会话空态面板独立占满中区，避免空白状态下只剩几颗按钮和一大段无意义留白。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: AppPalette.lineStrong,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSettingsRequested,
                  child: const Text('工作台设置'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: AppPalette.mutedText,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: PrimaryActionList(
                  actions: actions,
                  actionHandler: actionHandler,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
