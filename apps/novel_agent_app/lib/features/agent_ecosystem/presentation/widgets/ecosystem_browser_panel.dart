import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/agent_ecosystem_view_data.dart';

class EcosystemBrowserPanel extends StatelessWidget {
  const EcosystemBrowserPanel({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.entries,
    required this.statusMessage,
    this.isBusy = false,
    required this.onRefreshRequested,
    required this.onImportPackageRequested,
    required this.onGenerateIndexRequested,
    required this.onTabSelected,
    required this.onEntrySelected,
  });

  final List<EcosystemTabViewData> tabs;
  final String activeTabId;
  final List<EcosystemEntryViewData> entries;
  final String statusMessage;
  final bool isBusy;
  final VoidCallback onRefreshRequested;
  final VoidCallback onImportPackageRequested;
  final VoidCallback onGenerateIndexRequested;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<String> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    final colors = context.novelThemeColors;
    // 中文注释: 生态浏览面板集中承接顶部动作、tab 和条目列表，但不把详情和新建入口也揉进来。
    return PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ActionButton(
                label: '刷新列表',
                icon: Icons.refresh_rounded,
                tone: ActionButtonTone.neutral,
                disabled: isBusy,
                onPressed: onRefreshRequested,
              ),
              ActionButton(
                label: '导入生态包',
                icon: Icons.file_upload_outlined,
                disabled: isBusy,
                onPressed: onImportPackageRequested,
              ),
              ActionButton(
                label: '生成索引',
                icon: Icons.auto_awesome_motion_outlined,
                tone: ActionButtonTone.warm,
                disabled: isBusy,
                onPressed: onGenerateIndexRequested,
              ),
            ],
          ),
          if (statusMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.mutedTextColor,
              ),
            ),
          ],
          const SizedBox(height: 14),
          HorizontalOverflowScrollbar(
            builder: (context, controller) => SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: tabs
                    .map(
                      (tab) => ButtonSegment<String>(
                        value: tab.id,
                        label: Text(tab.label),
                      ),
                    )
                    .toList(),
                selected: {activeTabId},
                showSelectedIcon: false,
                onSelectionChanged: (selection) {
                  // 中文注释: tab 切换只回传 id，由外层控制器维护整个生态页的视图状态。
                  onTabSelected(selection.first);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surface.backgroundColor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(surface.radius),
                border: Border.all(color: surface.borderColor, width: 1),
              ),
              child: entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.smart_toy_outlined,
                      message: '还没有智能体或技能',
                      hint: '点上方"导入生态包"或"生成索引"以开始。',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: entries.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Material(
                          color: entry.isSelected
                              ? colors.accentSoftColor.withValues(alpha: 0.72)
                              : surface.backgroundColor.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: entry.isSelected
                                    ? colors.lineStrongColor
                                    : surface.borderColor,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                entry.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textColor,
                                ),
                              ),
                              subtitle: Text(
                                '[${entry.badge}] ${entry.subtitle}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.mutedTextColor,
                                ),
                              ),
                              onTap: () {
                                // 中文注释: 条目点击只把 id 交给外层，详情面板不由列表内部直接操控。
                                onEntrySelected(entry.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
