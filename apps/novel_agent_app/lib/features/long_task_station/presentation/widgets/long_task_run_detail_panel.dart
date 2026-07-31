import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../workbench/presentation/contracts/pending_research_action_handler.dart';
import '../contracts/long_task_station_action_handler.dart';
import '../models/long_task_station_view_data.dart';
import 'long_task_run_action_bar.dart';
import 'long_task_run_attention_callout.dart';

class LongTaskRunDetailPanel extends StatelessWidget {
  const LongTaskRunDetailPanel({
    super.key,
    required this.detail,
    required this.actionHandler,
    this.pendingResearchActionHandler,
  });

  final LongTaskRunDetailViewData? detail;
  final LongTaskStationActionHandler actionHandler;
  final PendingResearchActionHandler? pendingResearchActionHandler;

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
            if (run.runtimeBaselineTitle.trim().isNotEmpty)
              _Badge(text: run.runtimeBaselineTitle),
            _Badge(text: run.runtimeModeLabel),
            if (run.storageStrategyLabel.trim().isNotEmpty)
              _Badge(text: run.storageStrategyLabel),
            ...run.policyBadges.map((item) => _Badge(text: item)),
          ],
        ),
        const SizedBox(height: 12),
        LongTaskRunActionBar(run: run, actionHandler: actionHandler),
        LongTaskRunAttentionCallout(run: run, actionHandler: actionHandler),
        const SizedBox(height: 16),
        if (run.overviewBlocks.isNotEmpty)
          ...run.overviewBlocks.map(
            (block) => _OverviewBlock(
              runId: run.id,
              block: block,
              actionHandler: actionHandler,
              pendingResearchActionHandler: pendingResearchActionHandler,
            ),
          )
        else if (run.primaryMetadata.isNotEmpty)
          ...run.primaryMetadata.map(
            (item) => _MetaLine(label: item.label, value: item.value),
          ),
        _SectionTitle(title: '当前链路'),
        if (run.isDetailLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        // 中文注释: detail 加载失败时要与"干净空"区分开——用警示色放大显示，避免被弱化的元数据淹没。
        Builder(builder: (context) {
          final message = run.detailStatusMessage;
          final isFailure = message.startsWith('读取运行详情失败');
          if (message.trim().isEmpty) {
            return const SizedBox.shrink();
          }
          if (isFailure) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }
          return Text(message, style: Theme.of(context).textTheme.bodySmall);
        }),
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
        if (run.narrativeActivation != null ||
            run.narrativeDelivery != null ||
            run.narrativeReview != null ||
            run.narrativeContinuity != null ||
            run.informationSummary != null ||
            run.narrativeProjectionItems.isNotEmpty ||
            run.narrativePermissionItems.isNotEmpty ||
            run.informationProjectionItems.isNotEmpty ||
            run.informationPermissionItems.isNotEmpty) ...[
          _SectionTitle(title: run.narrativeSectionTitle),
          _RelatedItemSection(
            title: run.narrativeActivationLabel,
            item: run.narrativeActivation,
            pendingResearchActionHandler: pendingResearchActionHandler,
            onOpenRequested:
                run.narrativeActivation == null ||
                    run.narrativeActivation!.relativePath.trim().isEmpty
                ? null
                : () => actionHandler.onLongTaskStationResourceRequested(
                    run.id,
                    run.narrativeActivation!.relativePath,
                  ),
          ),
          _RelatedItemSection(
            title: run.narrativeDeliveryLabel,
            item: run.narrativeDelivery,
            pendingResearchActionHandler: pendingResearchActionHandler,
            onOpenRequested:
                run.narrativeDelivery == null ||
                    run.narrativeDelivery!.relativePath.trim().isEmpty
                ? null
                : () => actionHandler.onLongTaskStationResourceRequested(
                    run.id,
                    run.narrativeDelivery!.relativePath,
                  ),
          ),
          _RelatedItemSection(
            title: run.narrativeReviewLabel,
            item: run.narrativeReview,
            pendingResearchActionHandler: pendingResearchActionHandler,
            onOpenRequested:
                run.narrativeReview == null ||
                    run.narrativeReview!.relativePath.trim().isEmpty
                ? null
                : () => actionHandler.onLongTaskStationResourceRequested(
                    run.id,
                    run.narrativeReview!.relativePath,
                  ),
          ),
          _RelatedItemSection(
            title: run.narrativeContinuityLabel,
            item: run.narrativeContinuity,
            pendingResearchActionHandler: pendingResearchActionHandler,
            onOpenRequested:
                run.narrativeContinuity == null ||
                    run.narrativeContinuity!.relativePath.trim().isEmpty
                ? null
                : () => actionHandler.onLongTaskStationResourceRequested(
                    run.id,
                    run.narrativeContinuity!.relativePath,
                  ),
          ),
          _RelatedItemSection(
            title: run.informationSummaryLabel,
            item: run.informationSummary,
            pendingResearchActionHandler: pendingResearchActionHandler,
            onOpenRequested:
                run.informationSummary == null ||
                    run.informationSummary!.relativePath.trim().isEmpty
                ? null
                : () => actionHandler.onLongTaskStationResourceRequested(
                    run.id,
                    run.informationSummary!.relativePath,
                  ),
          ),
          if (run.narrativeProjectionItems.isNotEmpty) ...[
            _SectionTitle(title: run.narrativeProjectionSectionTitle),
            ...run.narrativeProjectionItems.map(
              (item) => _RelatedItemSection(
                title: item.title,
                item: item,
                pendingResearchActionHandler: pendingResearchActionHandler,
                onOpenRequested: item.relativePath.trim().isEmpty
                    ? null
                    : () => actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        item.relativePath,
                      ),
              ),
            ),
          ],
          if (run.informationProjectionItems.isNotEmpty) ...[
            _SectionTitle(title: run.informationProjectionSectionTitle),
            ...run.informationProjectionItems.map(
              (item) => _RelatedItemSection(
                title: item.title,
                item: item,
                pendingResearchActionHandler: pendingResearchActionHandler,
                onOpenRequested: item.relativePath.trim().isEmpty
                    ? null
                    : () => actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        item.relativePath,
                      ),
              ),
            ),
          ],
          if (run.narrativePermissionItems.isNotEmpty) ...[
            _SectionTitle(title: run.narrativePermissionSectionTitle),
            ...run.narrativePermissionItems.map(
              (item) => _RelatedItemSection(
                title: item.title,
                item: item,
                pendingResearchActionHandler: pendingResearchActionHandler,
                onOpenRequested: item.relativePath.trim().isEmpty
                    ? null
                    : () => actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        item.relativePath,
                      ),
              ),
            ),
          ],
          if (run.informationPermissionItems.isNotEmpty) ...[
            _SectionTitle(title: run.informationPermissionSectionTitle),
            ...run.informationPermissionItems.map(
              (item) => _RelatedItemSection(
                title: item.title,
                item: item,
                pendingResearchActionHandler: pendingResearchActionHandler,
                onOpenRequested: item.relativePath.trim().isEmpty
                    ? null
                    : () => actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        item.relativePath,
                      ),
              ),
            ),
          ],
        ],
        if (run.diagnosticMetadata.isNotEmpty) ...[
          _SectionTitle(title: '高级信息'),
          // 中文注释: 主元数据(项目路径)只在上方概览块非空、未走兜底展示时才在此列出，
          // 避免与概览兜底分支(primaryMetadata 在 overviewBlocks 为空时已渲染一次)重复。
          if (run.overviewBlocks.isNotEmpty)
            ...run.primaryMetadata.map(
              (item) => _MetaLine(label: item.label, value: item.value),
            ),
          ExpansionTile(
            title: Text(run.diagnosticSectionTitle),
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            initiallyExpanded: false,
            children: run.diagnosticMetadata
                .map((item) => _MetaLine(label: item.label, value: item.value))
                .toList(growable: false),
          ),
        ],
        _SectionTitle(title: run.relatedResultsSectionTitle),
        _RelatedItemSection(
          title: '最近检查点',
          item: run.latestCheckpointReview,
          pendingResearchActionHandler: pendingResearchActionHandler,
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
          pendingResearchActionHandler: pendingResearchActionHandler,
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
          pendingResearchActionHandler: pendingResearchActionHandler,
          onOpenRequested: run.latestRepairTask == null
              ? null
              : () => actionHandler.onLongTaskStationResourceRequested(
                  run.id,
                  run.latestRepairTask!.relativePath,
                ),
        ),
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

class _OverviewBlock extends StatelessWidget {
  const _OverviewBlock({
    required this.runId,
    required this.block,
    required this.actionHandler,
    this.pendingResearchActionHandler,
  });

  final String runId;
  final LongTaskRunOverviewBlockViewData block;
  final LongTaskStationActionHandler actionHandler;
  final PendingResearchActionHandler? pendingResearchActionHandler;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: context.novelThemeColors.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (block.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(block.summary, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (block.entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...block.entries.map(
              (item) => _MetaLine(label: item.label, value: item.value),
            ),
          ],
          if (block.resources.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...block.resources.map(
              (item) => _RelatedItemSection(
                title: item.title,
                item: item,
                pendingResearchActionHandler: pendingResearchActionHandler,
                onOpenRequested: item.relativePath.trim().isEmpty
                    ? null
                    : () => actionHandler.onLongTaskStationResourceRequested(
                        runId,
                        item.relativePath,
                      ),
              ),
            ),
          ],
        ],
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
        border: Border.all(color: context.novelThemeColors.lineColor),
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
    this.pendingResearchActionHandler,
  });

  final String title;
  final LongTaskRunRelatedItemViewData? item;
  final VoidCallback? onOpenRequested;
  final PendingResearchActionHandler? pendingResearchActionHandler;

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
        border: Border.all(color: context.novelThemeColors.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item!.title.trim() == title.trim()
                      ? item!.title
                      : '$title：${item!.title}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (onOpenRequested != null || item!.supportsPendingResearchActions) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onOpenRequested != null)
                  TextButton(
                    onPressed: onOpenRequested,
                    child: Text(item!.actionLabel),
                  ),
                if (item!.supportsPendingResearchActions &&
                    pendingResearchActionHandler != null)
                  TextButton(
                    onPressed: () => pendingResearchActionHandler!
                        .onPendingResearchApproved(item!.pendingResearchRequestId),
                    child: const Text('确认'),
                  ),
                if (item!.supportsPendingResearchActions &&
                    pendingResearchActionHandler != null)
                  TextButton(
                    onPressed: () => pendingResearchActionHandler!
                        .onPendingResearchRejected(item!.pendingResearchRequestId),
                    child: const Text('拒绝'),
                  ),
              ],
            ),
          ],
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
        border: Border.all(color: context.novelThemeColors.lineColor),
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
