import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/project_launcher_view_data.dart';
import 'project_create_panel.dart';
import 'project_open_panel.dart';

class ProjectLauncherOverlay extends StatelessWidget {
  const ProjectLauncherOverlay({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectLauncherViewData viewData;
  final ResourceManagerActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目启动浮层统一承接打开/创建两种模式，避免把弹层判断散落到工作台各个角落。
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 720,
              maxHeight: 560,
              minWidth: 320,
            ),
            child: PanelSurface(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      if (viewData.canDismiss)
                        IconButton(
                          onPressed: actionHandler.onProjectLauncherDismissed,
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 中文注释: 打开和创建在这里按模式切换，但各自的面板布局继续拆开保持单一职责。
    switch (viewData.mode) {
      case ProjectLauncherMode.open:
        return ProjectOpenPanel(
          projectsRootPath: viewData.projectsRootPath,
          entries: viewData.entries,
          status: viewData.status,
          onRefreshRequested: actionHandler.onProjectLauncherRefreshRequested,
          onProjectOpened: actionHandler.onProjectEntryOpened,
        );
      case ProjectLauncherMode.create:
        return ProjectCreatePanel(
          projectsRootPath: viewData.projectsRootPath,
          status: viewData.status,
          projectTypeOptions: viewData.projectTypeOptions,
          selectedProjectTypeId: viewData.selectedProjectTypeId,
          allowOpenExisting: viewData.allowOpenExisting,
          onOpenExistingRequested: actionHandler.onOpenProjectRequested,
          onCreateSubmitted: actionHandler.onProjectCreationSubmitted,
        );
    }
  }
}
