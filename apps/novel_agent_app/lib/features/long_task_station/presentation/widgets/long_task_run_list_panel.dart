import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/long_task_station_view_data.dart';

class LongTaskRunListPanel extends StatelessWidget {
  const LongTaskRunListPanel({
    super.key,
    required this.entries,
    required this.onRunSelected,
  });

  final List<LongTaskRunEntryViewData> entries;
  final ValueChanged<String> onRunSelected;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final toolSurface = context.novelThemeSurfaces.toolRow;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          '暂无运行实例',
          style: TextStyle(
            color: optionSurface.mutedForegroundColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return InkWell(
          onTap: () => onRunSelected(entry.id),
          child: Container(
            color: entry.isSelected
                ? optionSurface.highlightBackgroundColor
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: optionSurface.foregroundColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        entry.statusLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: entry.requiresAttention
                              ? toolSurface.highlightForegroundColor
                              : optionSurface.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: optionSurface.mutedForegroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.projectPath.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.projectPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: optionSurface.mutedForegroundColor,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  entry.taskLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: optionSurface.foregroundColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.recentActivityLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: optionSurface.mutedForegroundColor,
                  ),
                ),
                if (entry.badges.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: entry.badges
                        .map(
                          (item) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: optionSurface.borderColor,
                              ),
                            ),
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: optionSurface.foregroundColor,
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
