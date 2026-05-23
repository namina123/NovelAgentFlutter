import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';
import '../models/sub_agent_run_view_data.dart';

class SubAgentRunTile extends StatelessWidget {
  const SubAgentRunTile({super.key, required this.run});

  final SubAgentRunViewData run;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 子智能体运行条目专注于单次委派回放，避免面板层知道事件明细的布局细节。
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      shape: AppChrome.controlShape(sideColor: AppPalette.line),
      collapsedShape: AppChrome.controlShape(sideColor: AppPalette.line),
      backgroundColor: const Color(0xFFF7F7F2),
      collapsedBackgroundColor: const Color(0xFFF7F7F2),
      iconColor: AppPalette.lineStrong,
      collapsedIconColor: AppPalette.lineStrong,
      title: Text(
        run.agentName,
        style: const TextStyle(
          color: AppPalette.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${run.status} · 工具 ${run.toolCount} 次',
        style: const TextStyle(color: AppPalette.mutedText, fontSize: 12),
      ),
      children: [
        if (run.task.trim().isNotEmpty)
          _InfoBlock(label: '任务', content: run.task),
        if (run.summary.trim().isNotEmpty)
          _InfoBlock(label: '摘要', content: run.summary),
        if (run.content.trim().isNotEmpty)
          _InfoBlock(label: '结果', content: run.content),
        if (run.reasoning.trim().isNotEmpty)
          _InfoBlock(label: '推理', content: run.reasoning),
        if (run.events.isNotEmpty)
          _InfoBlock(label: '事件', content: run.events.join('\n')),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.content});

  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 子区块用统一样式呈现长文本，避免每个字段自己定义间距和字号。
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.lineStrong,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(
              color: AppPalette.text,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
