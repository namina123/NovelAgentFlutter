import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/sub_agent_run_view_data.dart';
import '../models/transcript_block_view_data.dart';
import '../models/user_option_view_data.dart';
import 'conversation_entry_tile.dart';
import 'conversation_generating_placeholder.dart';
import 'conversation_retry_banner.dart';
import 'sub_agent_activity_panel.dart';
import 'user_option_panel.dart';

class TranscriptBlockRenderContext {
  const TranscriptBlockRenderContext({
    required this.showToolDetails,
    required this.onRetryRequested,
    required this.onUserOptionSelected,
    required this.onSubAgentSelected,
    this.activeSubAgentRunId,
    this.onStopRequested,
  });

  final bool showToolDetails;
  final VoidCallback onRetryRequested;
  final ValueChanged<UserOptionViewData> onUserOptionSelected;
  final ValueChanged<SubAgentRunViewData> onSubAgentSelected;
  final String? activeSubAgentRunId;

  /// 生成占位卡上的「停止」入口；为空时占位卡不显示停止按钮（停止仍可经输入栏/命令面板触达）。
  final VoidCallback? onStopRequested;
}

class TranscriptBlockRendererRegistry {
  const TranscriptBlockRendererRegistry();

  Widget build(
    BuildContext context,
    TranscriptBlockViewData block,
    TranscriptBlockRenderContext renderContext,
  ) {
    switch (block.kind) {
      case TranscriptBlockKind.messageUser:
      case TranscriptBlockKind.messageAssistantStreaming:
      case TranscriptBlockKind.messageAssistantFinal:
        return _buildMessageBlock(
          block as TranscriptMessageBlockViewData,
          renderContext,
        );
      case TranscriptBlockKind.toolCompact:
        return ConversationEntryTile(
          entry: (block as TranscriptToolBlockViewData).entry,
          showToolDetails: renderContext.showToolDetails,
        );
      case TranscriptBlockKind.choiceGroup:
        return UserOptionPanel(
          options: (block as TranscriptChoiceGroupBlockViewData).options,
          onSelected: renderContext.onUserOptionSelected,
        );
      case TranscriptBlockKind.runtimeNotice:
        return ConversationEntryTile(
          entry: (block as TranscriptRuntimeNoticeBlockViewData).entry,
          showToolDetails: renderContext.showToolDetails,
        );
      case TranscriptBlockKind.retryBanner:
        return ConversationRetryBanner(
          retryRequest: (block as TranscriptRetryBannerBlockViewData).retryRequest,
          onRetryRequested: renderContext.onRetryRequested,
        );
      case TranscriptBlockKind.checkpointCard:
        return _CheckpointCard(
          block: block as TranscriptCheckpointCardBlockViewData,
        );
      case TranscriptBlockKind.subAgentPreview:
        return SubAgentActivityPanel(
          runs: (block as TranscriptSubAgentPreviewBlockViewData).runs,
          activeRunId: renderContext.activeSubAgentRunId,
          onSelected: renderContext.onSubAgentSelected,
        );
    }
  }

  Widget _buildMessageBlock(
    TranscriptMessageBlockViewData block,
    TranscriptBlockRenderContext renderContext,
  ) {
    if (block.isPlaceholder) {
      return ConversationGeneratingPlaceholder(
        onStopRequested: renderContext.onStopRequested,
      );
    }
    return ConversationEntryTile(entry: block.entry);
  }
}

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({required this.block});

  final TranscriptCheckpointCardBlockViewData block;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface.backgroundColor,
        border: Border.all(color: surface.borderColor, width: AppChrome.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: TextStyle(
              color: surface.foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (block.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              block.summary,
              style: TextStyle(
                color: colors.textColor,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (block.status.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.status,
              style: TextStyle(
                color: surface.mutedForegroundColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
