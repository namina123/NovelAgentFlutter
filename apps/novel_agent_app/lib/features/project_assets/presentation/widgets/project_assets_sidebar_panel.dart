import 'package:flutter/material.dart';

import '../../../../shared/theme/novel_theme_context.dart';
import '../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../contracts/project_assets_action_handler.dart';
import '../models/project_assets_view_data.dart';
import '../models/project_rag_extraction_view_data.dart';

/// 缺失引用 key 形如 `foreshadow:abc123`——原始 ID 对用户无意义，按"类别"聚合成人话标签
/// （伏笔 / 时间线 / 角色等），并合并计数，告诉用户该补建哪类资产。
const Map<String, String> _missingReferenceKindLabels = <String, String>{
  'foreshadow': '伏笔',
  'timeline': '时间线',
  'relationship': '关系',
  'character': '角色',
  'organization': '组织',
  'world_rule': '世界规则',
  'knowledge_card': '知识卡',
  'design_element': '设计要素',
  'reference_work': '参考作品',
  'research_note': '研究笔记',
};

List<String> _humanizeMissingReferenceKinds(List<String> keys) {
  final counts = <String, int>{};
  for (final key in keys) {
    final colon = key.indexOf(':');
    final kind =
        (colon >= 0 ? key.substring(0, colon) : key).trim().toLowerCase();
    final label = _missingReferenceKindLabels[kind] ?? '其他资产';
    counts[label] = (counts[label] ?? 0) + 1;
  }
  final ordered = counts.keys.toList()..sort();
  return ordered
      .map(
        (label) =>
            counts[label]! > 1 ? '$label ×${counts[label]}' : label,
      )
      .toList(growable: false);
}

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
    final colors = context.novelThemeColors;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // 中文注释: 这三个标签是「关联资产概览」（只读统计），不是右侧列表的筛选器——
          // 给一个明确的「概览」标题 + 信息提示，避免用户点了图谱以为列表会跟着过滤。
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: Row(
              children: [
                Text(
                  '概览',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: colors.mutedTextColor,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: '此处为关联资产概览（图谱/时间线/语料统计），不会筛选右侧列表。',
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: colors.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          HorizontalOverflowScrollbar(
            builder: (context, controller) => TabBar(
              controller: DefaultTabController.of(context),
              isScrollable: true,
              tabs: const <Tab>[
                Tab(text: '图谱'),
                Tab(text: '时间线'),
                Tab(text: '语料'),
              ],
            ),
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
            '分片 ${viewData.corpusSummary.chunkCountLabel} · 章 ${viewData.corpusSummary.chapterCountLabel}',
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
          const SizedBox(height: 4),
          Text(
            '以下被引用的资产尚不存在，可去对应面板补建：',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ..._humanizeMissingReferenceKinds(viewData.missingReferenceKeys).map(
            (label) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
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
