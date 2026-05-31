import 'package:flutter/material.dart';

import '../contracts/long_task_station_action_handler.dart';
import '../models/long_task_station_view_data.dart';
import 'long_task_run_action_bar.dart';
import 'long_task_run_attention_callout.dart';

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
        Text(
          run.projectTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _Badge(text: run.statusLabel),
            _Badge(text: run.runtimeBaselineTitle),
            _Badge(text: run.runtimeModeLabel),
            _Badge(text: run.storageStrategyLabel),
            ...run.policyBadges.map((item) => _Badge(text: item)),
          ],
        ),
        const SizedBox(height: 12),
        LongTaskRunActionBar(run: run, actionHandler: actionHandler),
        LongTaskRunAttentionCallout(run: run, actionHandler: actionHandler),
        const SizedBox(height: 16),
        _MetaLine(label: '项目路径', value: run.projectPath),
        _MetaLine(label: '基准说明', value: run.runtimeBaselineDescription),
        _MetaLine(label: '运行模式', value: run.runtimeModeLabel),
        _MetaLine(label: '工作流 ID', value: run.workflowStrategyId),
        _MetaLine(label: '活动任务', value: run.activeTaskLabel),
        if (run.activeTaskPath.trim().isNotEmpty)
          _MetaLine(label: '活动任务路径', value: run.activeTaskPath),
        if (run.activeTaskStatusLabel.trim().isNotEmpty)
          _MetaLine(label: '活动任务状态', value: run.activeTaskStatusLabel),
        if (run.activeTaskSummary.trim().isNotEmpty)
          _MetaLine(label: '活动任务摘要', value: run.activeTaskSummary),
        _SectionTitle(title: '当前阻塞'),
        _MetaLine(label: '阻塞标签', value: run.blockerLabel),
        _MetaLine(label: '阻塞说明', value: run.blockerNote),
        if (run.blockerDetail.trim().isNotEmpty)
          _MetaLine(label: '阻塞细节', value: run.blockerDetail),
        if (run.blockerActionHint.trim().isNotEmpty)
          _MetaLine(label: '建议动作', value: run.blockerActionHint),
        _SectionTitle(title: '当前链路'),
        if (run.isDetailLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        Text(
          run.detailStatusMessage,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        _MetaLine(label: '链路标题', value: run.taskChainTitle),
        _MetaLine(label: '链路摘要', value: run.taskChainSubtitle),
        if (run.taskChainItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('当前没有可展示的链路节点。'),
          )
        else
          ...run.taskChainItems.map(
            (item) => _ChainItemTile(
              item: item,
              onOpenRequested: item.relativePath.trim().isEmpty
                  ? null
                  : () => actionHandler.onLongTaskStationResourceRequested(
                      run.id,
                      item.relativePath,
                    ),
            ),
          ),
        _SectionTitle(title: '最近关联结果'),
        _RelatedItemSection(
          title: '最近检查点',
          item: run.latestCheckpointReview,
          onOpenRequested: run.latestCheckpointReview == null
              ? null
              : () => actionHandler.onLongTaskStationResourceRequested(
                  run.id,
                  run.latestCheckpointReview!.relativePath,
                ),
        ),
        _RelatedItemSection(
          title: '最近审稿',
          item: run.latestReviewReport,
          onOpenRequested: run.latestReviewReport == null
              ? null
              : () => actionHandler.onLongTaskStationResourceRequested(
                  run.id,
                  run.latestReviewReport!.relativePath,
                ),
        ),
        _RelatedItemSection(
          title: '最近返工任务',
          item: run.latestRepairTask,
          onOpenRequested: run.latestRepairTask == null
              ? null
              : () => actionHandler.onLongTaskStationResourceRequested(
                  run.id,
                  run.latestRepairTask!.relativePath,
                ),
        ),
        if (run.stopReasonLabel.trim().isNotEmpty && run.stopReasonLabel != '无')
          _MetaLine(label: '停止/阻塞原因', value: run.stopReasonLabel),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ChainItemTile extends StatelessWidget {
  const _ChainItemTile({required this.item, required this.onOpenRequested});

  final LongTaskRunChainItemViewData item;
  final VoidCallback? onOpenRequested;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onOpenRequested != null)
                TextButton(onPressed: onOpenRequested, child: const Text('查看')),
            ],
          ),
          const SizedBox(height: 4),
          Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
          if (item.relativePath.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            SelectableText(
              item.relativePath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _RelatedItemSection extends StatelessWidget {
  const _RelatedItemSection({
    required this.title,
    required this.item,
    required this.onOpenRequested,
  });

  final String title;
  final LongTaskRunRelatedItemViewData? item;
  final VoidCallback? onOpenRequested;

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _MetaLine(label: title, value: '暂无'),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title：${item!.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onOpenRequested != null)
                TextButton(
                  onPressed: onOpenRequested,
                  child: Text(item!.actionLabel),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(item!.subtitle, style: Theme.of(context).textTheme.bodySmall),
          if (item!.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item!.summary, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (item!.relativePath.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              item!.relativePath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
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
