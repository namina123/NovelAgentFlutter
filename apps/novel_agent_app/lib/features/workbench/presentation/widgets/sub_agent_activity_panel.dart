import 'package:flutter/material.dart';

import '../models/sub_agent_run_view_data.dart';
import '../services/sub_agent_run_preview_projection_service.dart';
import 'sub_agent_run_preview_card.dart';

class SubAgentActivityPanel extends StatelessWidget {
  const SubAgentActivityPanel({
    super.key,
    required this.runs,
    required this.onSelected,
    this.activeRunId,
    this.previewProjectionService = const SubAgentRunPreviewProjectionService(),
  });

  final List<SubAgentRunViewData> runs;
  final ValueChanged<SubAgentRunViewData> onSelected;
  final String? activeRunId;
  final SubAgentRunPreviewProjectionService previewProjectionService;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 子智能体活动面板只负责呈现可进入的缩略卡片，不承担详情页或主会话状态切换职责。
    if (runs.isEmpty) {
      return const SizedBox.shrink();
    }
    final previewItems = runs.reversed
        .map(
          (run) => (
            run: run,
            preview: previewProjectionService.build(run),
          ),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: previewItems
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SubAgentRunPreviewCard(
                viewData: item.preview,
                isActive: item.preview.id == activeRunId,
                onTap: () => onSelected(item.run),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}
