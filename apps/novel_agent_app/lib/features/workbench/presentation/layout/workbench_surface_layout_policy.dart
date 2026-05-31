import '../../../../app/layout/app_layout_metrics.dart';
import '../../../../app/layout/app_layout_mode.dart';
import 'workbench_surface_layout.dart';

class WorkbenchSurfaceLayoutPolicy {
  const WorkbenchSurfaceLayoutPolicy._();

  static WorkbenchSurfaceLayout resolve({
    required AppLayoutMetrics metrics,
    required bool isDocumentsWorkspaceVisible,
  }) {
    // 中文注释: 工作台页面只消费布局决策结果；真正的退化规则统一放在策略层，后续调整比例时不需要改页面结构。
    if (!isDocumentsWorkspaceVisible &&
        metrics.isKeyboardVisible &&
        metrics.isLandscape &&
        !metrics.isTabletLike) {
      return const WorkbenchSurfaceLayout(
        mode: WorkbenchSurfaceMode.immersiveConversation,
        showWorkspaceShortcuts: true,
      );
    }
    if (metrics.mode == AppLayoutMode.expanded) {
      return const WorkbenchSurfaceLayout(
        mode: WorkbenchSurfaceMode.threePane,
        showWorkspaceShortcuts: false,
      );
    }
    if (metrics.mode == AppLayoutMode.compact) {
      return const WorkbenchSurfaceLayout(
        mode: WorkbenchSurfaceMode.compactWorkbench,
        showWorkspaceShortcuts: false,
      );
    }
    if (isDocumentsWorkspaceVisible) {
      return const WorkbenchSurfaceLayout(
        mode: WorkbenchSurfaceMode.documentsWorkspace,
        showWorkspaceShortcuts: false,
      );
    }
    if (metrics.mode == AppLayoutMode.medium) {
      return const WorkbenchSurfaceLayout(
        mode: WorkbenchSurfaceMode.twoPane,
        showWorkspaceShortcuts: true,
      );
    }
    return const WorkbenchSurfaceLayout(
      mode: WorkbenchSurfaceMode.singleConversation,
      showWorkspaceShortcuts: true,
    );
  }
}
