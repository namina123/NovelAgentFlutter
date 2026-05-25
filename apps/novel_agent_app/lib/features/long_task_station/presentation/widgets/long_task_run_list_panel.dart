import 'package:flutter/material.dart';

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
    if (entries.isEmpty) {
      return const Center(child: Text('暂无运行实例'));
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          dense: true,
          selected: entry.isSelected,
          title: Text(entry.title),
          subtitle: Text('${entry.subtitle}\n${entry.taskLabel}'),
          isThreeLine: true,
          onTap: () => onRunSelected(entry.id),
        );
      },
    );
  }
}
