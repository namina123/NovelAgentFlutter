import 'package:flutter/material.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../contracts/project_assets_action_handler.dart';
import '../models/project_assets_view_data.dart';

class ProjectAssetsEntryListPanel extends StatelessWidget {
  const ProjectAssetsEntryListPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectAssetsViewData viewData;
  final ProjectAssetsActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HorizontalOverflowScrollbar(
          builder: (context, controller) => SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: viewData.tabs
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.label),
                        selected: item.id == viewData.activeTabId,
                        onSelected: (_) =>
                            actionHandler.onProjectAssetsTabSelected(item.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: viewData.entries.isEmpty
              ? const EmptyState(
                  icon: Icons.inbox_outlined,
                  message: '当前分类还没有条目',
                  hint: '先在主面板完成参考资料提取或导入语料后再回来查看。',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: viewData.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = viewData.entries[index];
                    return InkWell(
                      onTap: () =>
                          actionHandler.onProjectAssetsEntrySelected(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).dividerColor,
                          ),
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (item.badge.trim().isNotEmpty)
                                  Text(
                                    item.badge,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            if (item.subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (item.meta.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
