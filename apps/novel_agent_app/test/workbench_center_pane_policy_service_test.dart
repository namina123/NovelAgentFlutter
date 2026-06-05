import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_center_pane_policy_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_auxiliary_panel_id.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_workspace_shell_view_data.dart';

void main() {
  const service = WorkbenchCenterPanePolicyService();

  test('center pane keeps document workspace as primary object', () {
    final viewData = service.build(_shellViewData());

    expect(viewData.primaryTitle, '正文工作区');
    expect(viewData.primaryDescription, contains('当前文档'));
    expect(viewData.auxiliaryTitle, '辅助视图');
    expect(viewData.canRevealAuxiliary, isTrue);
    expect(
      viewData.descriptorFor(WorkbenchAuxiliaryPanelId.reviewAnalysis).label,
      '审稿锚点',
    );
  });

  test(
    'center pane hides auxiliary reveal when no document or signals exist',
    () {
      final viewData = service.build(
        _shellViewData(
          activeDocumentPath: '',
          activeDocumentTitle: '',
          activeDocumentBody: '',
          contextSummary: '',
          generationStatus: '',
        ),
      );

      expect(viewData.canRevealAuxiliary, isFalse);
    },
  );
}

WorkbenchWorkspaceShellViewData _shellViewData({
  String activeDocumentTitle = 'chapter_01.md',
  String activeDocumentPath = 'chapters/chapter_01.md',
  String activeDocumentBody = '正文内容',
  String contextSummary = '已载入上下文。',
  String generationStatus = '待命',
}) {
  return WorkbenchWorkspaceShellViewData(
    projectName: '项目',
    projectSubtitle: '',
    resourceCount: 3,
    activeDocumentTitle: activeDocumentTitle,
    activeDocumentPath: activeDocumentPath,
    activeDocumentBody: activeDocumentBody,
    activeDocumentDirty: false,
    activeDocumentCanRender: true,
    generationStatus: generationStatus,
    contextSummary: contextSummary,
    workflowTitle: '章节协作',
    workflowDescription: '围绕正文协作。',
    modelLabel: '模型',
    agentGroupLabel: '长篇总控组',
    primaryAgentLabel: '综合创作智能体',
    toolCoreStatus: '',
    pendingOptionCount: 0,
    subAgentRunCount: 0,
    isGenerating: false,
    projectAgentGroupPanel: const ProjectAgentGroupPanelViewData(
      currentGroupLabel: '长篇总控组',
      primaryAgentLabel: '综合创作智能体',
      summary: '当前项目已确定默认协作组，写作时会沿用这套协作摘要。',
      actionTitle: '项目智能体组',
      actionDescription: '查看当前项目协作摘要，并按需调整默认协作组。',
      canConfigure: true,
    ),
  );
}
