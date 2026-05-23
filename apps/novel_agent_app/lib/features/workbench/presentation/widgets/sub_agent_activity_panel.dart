import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../models/sub_agent_run_view_data.dart';
import 'sub_agent_run_tile.dart';

class SubAgentActivityPanel extends StatelessWidget {
  const SubAgentActivityPanel({super.key, required this.runs});

  final List<SubAgentRunViewData> runs;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 子智能体活动面板只聚合委派记录，不承担主会话时间线的排序规则。
    if (runs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '协作活动',
          style: TextStyle(
            color: AppPalette.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...runs.reversed.map(
          (run) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SubAgentRunTile(run: run),
          ),
        ),
      ],
    );
  }
}
