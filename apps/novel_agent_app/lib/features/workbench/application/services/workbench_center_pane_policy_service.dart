import '../../presentation/models/workbench_auxiliary_panel_id.dart';
import '../../presentation/models/workbench_center_auxiliary_panel_view_data.dart';
import '../../presentation/models/workbench_center_pane_view_data.dart';
import '../../presentation/models/workbench_workspace_shell_view_data.dart';

class WorkbenchCenterPanePolicyService {
  const WorkbenchCenterPanePolicyService();

  WorkbenchCenterPaneViewData build(WorkbenchWorkspaceShellViewData viewData) {
    return WorkbenchCenterPaneViewData(
      primaryTitle: '正文工作区',
      primaryDescription: '中栏主对象始终是当前文档，源码、渲染、结构只是同一文档的查看方式。',
      auxiliaryTitle: '辅助视图',
      auxiliaryRevealLabel: '辅助视图',
      canRevealAuxiliary: _canRevealAuxiliary(viewData),
      auxiliaryPanels: const [
        WorkbenchCenterAuxiliaryPanelViewData(
          panelId: WorkbenchAuxiliaryPanelId.promptPreview,
          label: '协作基线',
          description: '查看当前协作基线与上下文摘要。',
        ),
        WorkbenchCenterAuxiliaryPanelViewData(
          panelId: WorkbenchAuxiliaryPanelId.rewritePreview,
          label: '当前文档',
          description: '查看当前文档切片与当前操作锚点。',
        ),
        WorkbenchCenterAuxiliaryPanelViewData(
          panelId: WorkbenchAuxiliaryPanelId.reviewAnalysis,
          label: '审稿锚点',
          description: '查看当前文档的审稿信号与返工入口。',
        ),
        WorkbenchCenterAuxiliaryPanelViewData(
          panelId: WorkbenchAuxiliaryPanelId.contextSelection,
          label: '上下文',
          description: '查看当前会话可见的上下文与关联信号。',
        ),
      ],
    );
  }

  bool _canRevealAuxiliary(WorkbenchWorkspaceShellViewData viewData) {
    return viewData.hasActiveDocument ||
        viewData.contextSummary.trim().isNotEmpty ||
        viewData.generationStatus.trim().isNotEmpty;
  }
}
