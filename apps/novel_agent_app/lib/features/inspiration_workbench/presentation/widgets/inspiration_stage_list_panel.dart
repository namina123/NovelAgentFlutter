import 'package:flutter/material.dart';

import '../contracts/inspiration_workbench_action_handler.dart';
import '../models/inspiration_workbench_view_data.dart';

class InspirationStageListPanel extends StatelessWidget {
  const InspirationStageListPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final InspirationWorkbenchViewData viewData;
  final InspirationWorkbenchActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 阶段列表只负责浏览和切换阶段，不直接处理保存动作。
    if (viewData.stages.isEmpty) {
      return const Center(child: Text('当前模式还没有可编辑阶段。'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final stage = viewData.stages[index];
        return InkWell(
          onTap: () =>
              actionHandler.onInspirationWorkbenchStageSelected(stage.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: stage.isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (stage.isCurrent)
                      const Text(
                        '当前',
                        style: TextStyle(fontSize: 11, color: Color(0xFF2F6F5E)),
                      ),
                    if (stage.isCompleted)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 16),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stage.answerPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemCount: viewData.stages.length,
    );
  }
}
