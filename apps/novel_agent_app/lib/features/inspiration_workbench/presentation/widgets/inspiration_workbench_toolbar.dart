import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/toolbar_icon_button.dart';
import '../../../../shared/widgets/workspace_page_header.dart';
import '../contracts/inspiration_workbench_action_handler.dart';
import '../models/inspiration_workbench_view_data.dart';

class InspirationWorkbenchToolbar extends StatelessWidget {
  const InspirationWorkbenchToolbar({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final InspirationWorkbenchViewData viewData;
  final InspirationWorkbenchActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 顶部工具条只承接导航和刷新，不负责模式切换与阶段编辑。
    return WorkspacePageHeader(
      title: '灵感工作台',
      subtitle: viewData.projectTitle.trim().isEmpty
          ? null
          : viewData.projectTitle,
      trailing: Text(
        viewData.progressText,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onBackRequested: actionHandler.onInspirationWorkbenchBackRequested,
      actions: [
        if (viewData.longTaskLaunch.isVisible && viewData.longTaskLaunch.canLaunch)
          ActionButton(
            label: viewData.longTaskLaunch.actionLabel,
            icon: Icons.play_arrow_rounded,
            tone: ActionButtonTone.warm,
            compact: true,
            onPressed:
                actionHandler.onInspirationWorkbenchLongTaskLaunchRequested,
          ),
        ToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '刷新',
          onPressed: actionHandler.onInspirationWorkbenchRefreshRequested,
        ),
      ],
    );
  }
}
