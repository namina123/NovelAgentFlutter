import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/project_launcher_view_data.dart';
import 'project_create_panel.dart';
import 'project_guard_panel.dart';

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
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return Positioned.fill(
      child: ColoredBox(
        color: colors.canvasBackground.withValues(alpha: 0.72),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth >= 1200 ? 860 : 780,
                maxHeight: constraints.maxHeight * 0.9,
                minWidth: 320,
              ),
              child: PanelSurface(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      decoration: BoxDecoration(
                        color: surface.backgroundColor.withValues(alpha: 0.64),
                        border: Border(
                          bottom: BorderSide(
                            color: surface.borderColor.withValues(alpha: 0.84),
                            width: AppChrome.borderWidth,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '项目工作流',
                                  style: TextStyle(
                                    color: surface.foregroundColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  viewData.mode == ProjectLauncherMode.create
                                      ? '在工作台内完成项目初始化与入口选择。'
                                      : '先创建一个新项目，或接回已有工作区。',
                                  style: TextStyle(
                                    color: colors.mutedTextColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (viewData.canDismiss)
                            IconButton(
                              onPressed:
                                  actionHandler.onProjectLauncherDismissed,
                              icon: const Icon(Icons.close_rounded),
                              tooltip: '关闭',
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: _buildBody(),
                      ),
                    ),
                  ],
                ),
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
      case ProjectLauncherMode.guard:
        return ProjectGuardPanel(
          title: viewData.title,
          description: viewData.description,
          status: viewData.status,
          projectsRootPath: viewData.projectsRootPath,
          allowOpenExisting: viewData.allowOpenExisting,
          onCreateRequested: actionHandler.onCreateProjectRequested,
          onOpenExistingRequested: actionHandler.onOpenProjectRequested,
        );
      case ProjectLauncherMode.create:
        return ProjectCreatePanel(
          title: viewData.title,
          description: viewData.description,
          projectsRootPath: viewData.projectsRootPath,
          status: viewData.status,
          draftTitle: viewData.draftTitle,
          projectTypeOptions: viewData.projectTypeOptions,
          selectedProjectTypeId: viewData.selectedProjectTypeId,
          storageStrategyOptions: viewData.storageStrategyOptions,
          selectedStorageStrategyId: viewData.selectedStorageStrategyId,
          creationPhase: viewData.creationPhase,
          bookDeconstructionFollowupOptions:
              viewData.bookDeconstructionFollowupOptions,
          selectedBookDeconstructionFollowupRouteId:
              viewData.selectedBookDeconstructionFollowupRouteId,
          runtimeBaselineOptions: viewData.runtimeBaselineOptions,
          selectedRuntimeBaselineId: viewData.selectedRuntimeBaselineId,
          selectedProjectTypeRequiresRuntimeBaseline:
              viewData.selectedProjectTypeRequiresRuntimeBaseline,
          continuityInput: viewData.continuityInput,
          allowOpenExisting: viewData.allowOpenExisting,
          onOpenExistingRequested: actionHandler.onOpenProjectRequested,
          onBackRequested: actionHandler.onProjectCreationBackRequested,
          onCreateSubmitted: actionHandler.onProjectCreationSubmitted,
        );
    }
  }
}
