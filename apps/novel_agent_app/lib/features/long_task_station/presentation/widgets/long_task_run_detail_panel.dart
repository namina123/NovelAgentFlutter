import 'package:flutter/material.dart';

import '../contracts/long_task_station_action_handler.dart';
import '../models/long_task_station_view_data.dart';

class LongTaskRunDetailPanel extends StatelessWidget {
  const LongTaskRunDetailPanel({
    super.key,
    required this.detail,
    required this.actionHandler,
  });

  final LongTaskRunDetailViewData? detail;
  final LongTaskStationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const Center(child: Text('请选择一个运行实例查看详情'));
    }
    final run = detail!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(run.projectTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(run.statusLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: run.canPause
                  ? () => actionHandler.onLongTaskStationPauseRequested(run.id)
                  : null,
              child: const Text('暂停'),
            ),
            OutlinedButton(
              onPressed: run.canResume
                  ? () => actionHandler.onLongTaskStationResumeRequested(run.id)
                  : null,
              child: const Text('恢复'),
            ),
            OutlinedButton(
              onPressed: run.canStop
                  ? () => actionHandler.onLongTaskStationStopRequested(run.id)
                  : null,
              child: const Text('停止'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MetaLine(label: '项目路径', value: run.projectPath),
        _MetaLine(label: '运行基准', value: run.runtimeBaselineTitle),
        _MetaLine(label: '基准说明', value: run.runtimeBaselineDescription),
        _MetaLine(label: '模式 ID', value: run.modeId),
        _MetaLine(label: '工作流 ID', value: run.workflowStrategyId),
        _MetaLine(label: '存储策略', value: run.storageStrategyLabel),
        _MetaLine(label: '活动任务', value: run.activeTaskLabel),
        _MetaLine(label: '备注', value: run.note),
        _MetaLine(label: '创建时间', value: run.createdAtLabel),
        _MetaLine(label: '更新时间', value: run.updatedAtLabel),
        _MetaLine(label: '最近心跳', value: run.lastHeartbeatAtLabel),
        _MetaLine(label: '启动时间', value: run.startedAtLabel),
        _MetaLine(label: '停止时间', value: run.stoppedAtLabel),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
