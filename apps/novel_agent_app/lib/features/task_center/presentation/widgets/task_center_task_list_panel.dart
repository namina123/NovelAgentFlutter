import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/task_center_view_data.dart';

class TaskCenterTaskListPanel extends StatelessWidget {
  const TaskCenterTaskListPanel({
    super.key,
    required this.tasks,
    required this.onTaskSelected,
    required this.onTaskOpened,
  });

  final List<TaskCenterTaskItemViewData> tasks;
  final ValueChanged<String> onTaskSelected;
  final ValueChanged<String> onTaskOpened;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(title: '任务列表'),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final item = tasks[index];
                return ListTile(
                  dense: true,
                  selected: item.isSelected,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${item.badge}｜${item.subtitle}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => onTaskSelected(item.id),
                  trailing: IconButton(
                    onPressed: () => onTaskOpened(item.id),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
