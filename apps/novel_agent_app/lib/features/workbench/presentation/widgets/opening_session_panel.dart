import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/opening_panel_view_data.dart';

class OpeningSessionPanel extends StatelessWidget {
  const OpeningSessionPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final OpeningPanelViewData viewData;
  final ConversationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: opening 补充块只保留会话所需的只读项目状态，不再承担项目级智能体组配置入口职责。
    final hasCurrentGroup = viewData.currentGroupDisplayName.trim().isNotEmpty;
    final currentGroupStatus = hasCurrentGroup
        ? '当前默认组：${viewData.currentGroupDisplayName}'
        : '当前默认组尚未确认';
    final availabilitySummary = _buildAvailabilitySummary();
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewData.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            hasCurrentGroup
                ? '继续通过对话补齐开局信息即可；项目默认组已经回到项目层单独管理。'
                : '继续通过对话补齐开局信息即可；项目默认组需要回到项目层确认。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            viewData.summary,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          _ReadonlyStatusCard(
            items: [
              _ReadonlyStatusItem(label: '项目默认组', value: currentGroupStatus),
              _ReadonlyStatusItem(label: '适配状态', value: availabilitySummary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '项目级智能体组配置与适配详情请到项目面板查看。',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  String _buildAvailabilitySummary() {
    final supportedCount = viewData.supportedGroups.length;
    final unsupportedCount = viewData.unsupportedGroups.length;
    if (supportedCount == 0 && unsupportedCount == 0) {
      return '暂无更多说明';
    }
    if (unsupportedCount == 0) {
      return '当前项目有 $supportedCount 个可用智能体组';
    }
    if (supportedCount == 0) {
      return '当前没有可直接使用的智能体组，另有 $unsupportedCount 个待项目层查看原因';
    }
    return '当前项目有 $supportedCount 个可用智能体组，另有 $unsupportedCount 个需到项目层查看原因';
  }
}

class _ReadonlyStatusCard extends StatelessWidget {
  const _ReadonlyStatusCard({required this.items});

  final List<_ReadonlyStatusItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.value,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ReadonlyStatusItem {
  const _ReadonlyStatusItem({required this.label, required this.value});

  final String label;
  final String value;
}
