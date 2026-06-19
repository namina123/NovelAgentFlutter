import 'package:flutter/material.dart';

import '../contracts/project_assets_action_handler.dart';
import '../models/project_assets_view_data.dart';
import '../models/project_rag_extraction_view_data.dart';

class ProjectAssetsSidebarPanel extends StatelessWidget {
  const ProjectAssetsSidebarPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectAssetsViewData viewData;
  final ProjectAssetsActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: <Tab>[
              Tab(text: '图谱'),
              Tab(text: '时间线'),
              Tab(text: '语料'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _GraphPane(
                  viewData: viewData.graph,
                  onReferenceSelected: actionHandler.onProjectAssetsReferenceSelected,
                ),
                _TimelinePane(
                  viewData: viewData.timeline,
                  onTimelineSelected: (timelineId) => actionHandler
                      .onProjectAssetsReferenceSelected('timeline:$timelineId'),
                ),
                _RagSummaryPane(viewData: viewData.ragExtraction),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RagSummaryPane extends StatelessWidget {
  const _RagSummaryPane({required this.viewData});

  final ProjectRagExtractionViewData viewData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '语料摘要',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(
          viewData.corpusSummary.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          viewData.mountSummary.emptyMessage.isNotEmpty
              ? viewData.mountSummary.emptyMessage
              : '已挂载 ${viewData.mountSummary.bindingCount} 组语料。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (viewData.corpusSummary.corpusId.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'chunk ${viewData.corpusSummary.chunkCountLabel} · 章 ${viewData.corpusSummary.chapterCountLabel}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _GraphPane extends StatelessWidget {
  const _GraphPane({
    required this.viewData,
    required this.onReferenceSelected,
  });

  final ProjectAssetsGraphViewData viewData;
  final ValueChanged<String> onReferenceSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${viewData.totalNodeCount} 节点 / ${viewData.totalEdgeCount} 连接',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          viewData.focusTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (viewData.focusSummary.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(viewData.focusSummary, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        ...viewData.relatedAssets.map(
          (item) => Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: Text(item.badge),
              selected: item.isSelected,
              onTap: () => onReferenceSelected(item.referenceKey),
            ),
          ),
        ),
        if (viewData.relatedAssets.isEmpty)
          const Text('当前焦点还没有可显示的关联资产。'),
        if (viewData.missingReferenceKeys.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            '缺失引用',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...viewData.missingReferenceKeys.map(
            (item) => Text(item, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ],
    );
  }
}

class _TimelinePane extends StatelessWidget {
  const _TimelinePane({
    required this.viewData,
    required this.onTimelineSelected,
  });

  final ProjectAssetsTimelineViewData viewData;
  final ValueChanged<String> onTimelineSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: viewData.items.length,
      separatorBuilder: (_, _) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = viewData.items[index];
        return InkWell(
          onTap: () => onTimelineSelected(item.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(item.statusLabel),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '序号 ${item.sequenceLabel}${item.phaseLabel.isEmpty ? '' : ' · ${item.phaseLabel}'} · 关联 ${item.relatedCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
