import 'package:flutter/material.dart';

import '../models/conversation_status_summary_item_kind.dart';
import '../models/conversation_status_summary_item_view_data.dart';
import '../models/conversation_status_summary_view_data.dart';
import 'conversation_panel_style.dart';

class ConversationPanelStatusGroup extends StatelessWidget {
  const ConversationPanelStatusGroup({
    super.key,
    required this.viewData,
    required this.onItemPressed,
  });

  final ConversationStatusSummaryViewData viewData;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 状态组继续朝“内联协作摘要”收口，避免消息流上方再形成一排重芯片。
    if (viewData.items.isEmpty) {
      return const SizedBox.shrink();
    }
    final style = ConversationPanelStyle.of(context);
    final expandedItems = viewData.expandedItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: style.gap(-2.1, min: 2),
          runSpacing: style.gap(-2.1, min: 2),
          children: viewData.items
              .map(
                (item) => _ConversationStatusChip(
                  item: item,
                  onPressed: item.isInteractive
                      ? () => onItemPressed(item.id)
                      : null,
                ),
              )
              .toList(growable: false),
        ),
        if (expandedItems.isNotEmpty) ...[
          SizedBox(height: style.gap(-0.75, min: 3)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: expandedItems
                .map((item) => _ConversationStatusDetail(item: item))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _ConversationStatusChip extends StatelessWidget {
  const _ConversationStatusChip({required this.item, this.onPressed});

  final ConversationStatusSummaryItemViewData item;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单个状态 chip 只关心展示和命中区域，业务含义已经由上游 service 固化。
    final style = ConversationPanelStyle.of(context);
    final backgroundColor = item.isHighlighted
        ? style.accentBandBackgroundColor
        : style.bandBackgroundColor;
    final foregroundColor = item.isHighlighted
        ? style.accentBandForegroundColor
        : style.foregroundColor;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(style.sectionRadius),
        border: Border(
          top: BorderSide(color: style.bandBorderColor.withValues(alpha: 0.24)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconOf(item.kind), size: 12, color: foregroundColor),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 156),
              child: Text.rich(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.label} ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.isHighlighted
                            ? foregroundColor.withValues(alpha: 0.82)
                            : style.mutedForegroundColor,
                      ),
                    ),
                    TextSpan(
                      text: item.summary,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.isBusy) ...[
              const SizedBox(width: 5),
              SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              ),
            ] else if (item.isInteractive) ...[
              const SizedBox(width: 3),
              Icon(
                item.isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: foregroundColor,
              ),
            ],
          ],
        ),
      ),
    );
    if (onPressed == null) {
      return KeyedSubtree(
        key: ValueKey<String>('conversation_status_${item.id}'),
        child: content,
      );
    }
    return KeyedSubtree(
      key: ValueKey<String>('conversation_status_${item.id}'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onPressed, child: content),
      ),
    );
  }

  IconData _iconOf(ConversationStatusSummaryItemKind kind) {
    // 中文注释: 状态 icon 由类别统一映射，避免外部 view data 混入具体图标资源。
    switch (kind) {
      case ConversationStatusSummaryItemKind.context:
        return Icons.analytics_outlined;
      case ConversationStatusSummaryItemKind.tools:
        return Icons.tune_outlined;
      case ConversationStatusSummaryItemKind.runtime:
        return Icons.cloud_sync_outlined;
    }
  }
}

class _ConversationStatusDetail extends StatelessWidget {
  const _ConversationStatusDetail({required this.item});

  final ConversationStatusSummaryItemViewData item;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 展开说明保持轻量文本行，给后续更正式的明细面板保留可替换边界。
    final style = ConversationPanelStyle.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(
        '${item.label}：${item.detail}',
        style: TextStyle(
          fontSize: 10,
          height: 1.45,
          color: style.mutedForegroundColor,
        ),
      ),
    );
  }
}
