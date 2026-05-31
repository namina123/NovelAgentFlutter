import '../../presentation/models/project_agent_group_panel_view_data.dart';
import 'project_agent_group_display_text_policy.dart';

class ProjectAgentGroupPanelViewDataService {
  const ProjectAgentGroupPanelViewDataService({
    ProjectAgentGroupDisplayTextPolicy? displayTextPolicy,
  }) : _displayTextPolicy =
           displayTextPolicy ?? const ProjectAgentGroupDisplayTextPolicy();

  final ProjectAgentGroupDisplayTextPolicy _displayTextPolicy;

  ProjectAgentGroupPanelViewData build({
    required bool hasActiveProject,
    required String currentGroupLabel,
    required String primaryAgentLabel,
  }) {
    // 中文注释: 项目面板上的协作配置摘要单独投影，避免面板组件自己判断“有没有项目”“是不是开局中”。
    if (!hasActiveProject) {
      return const ProjectAgentGroupPanelViewData(
        currentGroupLabel: '未打开项目',
        primaryAgentLabel: '综合创作智能体',
        summary: '先打开项目，再为当前项目确定默认智能体组。',
        actionTitle: '项目智能体组',
        actionDescription: '打开项目后，这里会成为当前项目的正式协作配置入口。',
        canConfigure: false,
      );
    }
    final resolvedGroupLabel = _displayTextPolicy.currentGroupLabel(
      currentGroupLabel,
    );
    final resolvedPrimaryAgentLabel = _displayTextPolicy.primaryAgentLabel(
      primaryAgentLabel,
    );
    final hasConfiguredGroup = _displayTextPolicy.hasResolvedGroup(
      resolvedGroupLabel,
    );
    if (!hasConfiguredGroup) {
      return ProjectAgentGroupPanelViewData(
        currentGroupLabel:
            ProjectAgentGroupDisplayTextPolicy.unresolvedGroupLabel,
        primaryAgentLabel: resolvedPrimaryAgentLabel,
        summary: _displayTextPolicy.unconfiguredProjectPanelSummary(),
        actionTitle: '项目智能体组',
        actionDescription: _displayTextPolicy
            .configureProjectPanelActionDescription(hasResolvedGroup: false),
        canConfigure: true,
      );
    }
    return ProjectAgentGroupPanelViewData(
      currentGroupLabel: resolvedGroupLabel,
      primaryAgentLabel: resolvedPrimaryAgentLabel,
      summary: _displayTextPolicy.configuredProjectPanelSummary(),
      actionTitle: '项目智能体组',
      actionDescription: _displayTextPolicy
          .configureProjectPanelActionDescription(hasResolvedGroup: true),
      canConfigure: true,
    );
  }
}
