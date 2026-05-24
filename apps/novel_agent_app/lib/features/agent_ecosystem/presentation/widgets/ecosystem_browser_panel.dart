import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/agent_ecosystem_view_data.dart';

class EcosystemBrowserPanel extends StatelessWidget {
  const EcosystemBrowserPanel({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.entries,
    required this.statusMessage,
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
  final VoidCallback onRefreshRequested;
  final VoidCallback onImportPackageRequested;
  final VoidCallback onGenerateIndexRequested;
  final ValueChanged<String> onTabSelected;
  final ValueChanged<String> onEntrySelected;

  @override
  Widget build(BuildContext context) {
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
                onPressed: onRefreshRequested,
              ),
              ActionButton(
                label: '导入生态包',
                icon: Icons.file_upload_outlined,
                onPressed: onImportPackageRequested,
              ),
              ActionButton(
                label: '生成索引',
                icon: Icons.auto_awesome_motion_outlined,
                tone: ActionButtonTone.warm,
                onPressed: onGenerateIndexRequested,
              ),
            ],
          ),
          if (statusMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              statusMessage,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
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
          const SizedBox(height: 14),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.line, width: 1),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: entries.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Material(
                    color: entry.isSelected
                        ? AppPalette.accentSoft
                        : AppPalette.panel,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppPalette.line, width: 1),
                      ),
                      child: ListTile(
                        title: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.text,
                          ),
                        ),
                        subtitle: Text(
                          '[${entry.badge}] ${entry.subtitle}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.mutedText,
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
