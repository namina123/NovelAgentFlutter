import 'package:flutter/material.dart';

import '../../../../shared/widgets/toolbar_icon_button.dart';
import '../../../../shared/widgets/workspace_page_header.dart';

class LongTaskStationToolbar extends StatelessWidget {
  const LongTaskStationToolbar({
    super.key,
    required this.title,
    required this.description,
    required this.supervisorStatusLabel,
    required this.onBackRequested,
    required this.onTaskCenterRequested,
    required this.onRefreshRequested,
  });

  final String title;
  final String description;
  final String supervisorStatusLabel;
  final VoidCallback onBackRequested;
  final VoidCallback onTaskCenterRequested;
  final VoidCallback onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    return WorkspacePageHeader(
      title: title,
      subtitle: description,
      trailing: Text(
        supervisorStatusLabel,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onBackRequested: onBackRequested,
      actions: [
        ToolbarIconButton(
          icon: Icons.tune_rounded,
          tooltip: '任务中心',
          onPressed: onTaskCenterRequested,
        ),
        ToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          onPressed: onRefreshRequested,
        ),
      ],
    );
  }
}
