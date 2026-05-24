import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/task_center_view_data.dart';

class TaskCenterDiagnosticsPanel extends StatelessWidget {
  const TaskCenterDiagnosticsPanel({
    super.key,
    required this.chainMarkdown,
    required this.longTaskRuns,
    required this.taskQueueRuns,
    required this.longTaskRunLog,
    required this.taskQueueRunLog,
    required this.onLongTaskRunSelected,
    required this.onTaskQueueRunSelected,
  });

  final String chainMarkdown;
  final List<TaskCenterRunItemViewData> longTaskRuns;
  final List<TaskCenterRunItemViewData> taskQueueRuns;
  final String longTaskRunLog;
  final String taskQueueRunLog;
  final ValueChanged<String> onLongTaskRunSelected;
  final ValueChanged<String> onTaskQueueRunSelected;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(title: '链路与运行记录'),
            const SizedBox(height: 8),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: '链路树'),
                Tab(text: '长任务运行'),
                Tab(text: '队列日志'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  _MarkdownBody(
                    content: chainMarkdown.trim().isEmpty
                        ? '当前没有可展示的链路信息。'
                        : chainMarkdown,
                  ),
                  _RunLogView(
                    runs: longTaskRuns,
                    content: longTaskRunLog.trim().isEmpty
                        ? '当前没有长任务运行记录。'
                        : longTaskRunLog,
                    onSelected: onLongTaskRunSelected,
                  ),
                  _RunLogView(
                    runs: taskQueueRuns,
                    content: taskQueueRunLog.trim().isEmpty
                        ? '当前没有受控连续运行记录。'
                        : taskQueueRunLog,
                    onSelected: onTaskQueueRunSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunLogView extends StatelessWidget {
  const _RunLogView({
    required this.runs,
    required this.content,
    required this.onSelected,
  });

  final List<TaskCenterRunItemViewData> runs;
  final String content;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: ListView.builder(
            itemCount: runs.length,
            itemBuilder: (context, index) {
              final item = runs[index];
              return ListTile(
                dense: true,
                selected: item.isSelected,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => onSelected(item.relativePath),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _MarkdownBody(content: content)),
      ],
    );
  }
}

class _MarkdownBody extends StatelessWidget {
  const _MarkdownBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SelectableText(
        content,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.55,
          color: AppPalette.text,
        ),
      ),
    );
  }
}
