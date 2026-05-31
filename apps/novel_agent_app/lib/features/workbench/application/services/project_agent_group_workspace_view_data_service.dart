import '../models/opening_session_projection.dart';
import '../../presentation/models/project_agent_group_option_view_data.dart';
import '../../presentation/models/project_agent_group_unsupported_view_data.dart';
import '../../presentation/models/project_agent_group_workspace_view_data.dart';
import 'opening_unsupported_reason_text_service.dart';
import 'project_agent_group_display_text_policy.dart';

class ProjectAgentGroupWorkspaceViewDataService {
  const ProjectAgentGroupWorkspaceViewDataService({
    OpeningUnsupportedReasonTextService? unsupportedReasonTextService,
    ProjectAgentGroupDisplayTextPolicy? displayTextPolicy,
  }) : _unsupportedReasonTextService =
           unsupportedReasonTextService ??
           const OpeningUnsupportedReasonTextService(),
       _displayTextPolicy =
           displayTextPolicy ?? const ProjectAgentGroupDisplayTextPolicy();

  final OpeningUnsupportedReasonTextService _unsupportedReasonTextService;
  final ProjectAgentGroupDisplayTextPolicy _displayTextPolicy;

  ProjectAgentGroupWorkspaceViewData build({
    required OpeningSessionProjection projection,
  }) {
    // 中文注释: 项目级组配置浮层直接消费 opening projection，但输出成独立 view data，避免 project panel 继续依赖 opening 命名对象。
    final currentGroupLabel = _displayTextPolicy.currentGroupLabel(
      projection.currentGroupDisplayName,
    );
    final primaryAgentLabel = _displayTextPolicy.primaryAgentLabel(
      projection.currentPrimaryAgentSummary?.displayName,
    );
    return ProjectAgentGroupWorkspaceViewData(
      title: '项目智能体组',
      description: _descriptionOf(projection),
      currentGroupLabel: currentGroupLabel,
      primaryAgentLabel: primaryAgentLabel,
      primaryAgentDescription:
          projection.currentPrimaryAgentSummary?.role.trim() ?? '',
      selectionHint: _displayTextPolicy.workspaceSelectionHint(),
      supportedGroups: projection.supportedGroups
          .map(
            (summary) => ProjectAgentGroupOptionViewData(
              groupId: summary.groupId,
              displayName: summary.displayName,
              description: summary.description,
              isCurrent: summary.isCurrent,
              isDegraded: summary.isDegraded,
              members: summary.members,
            ),
          )
          .toList(growable: false),
      unsupportedGroups: projection.unsupportedGroups
          .map(
            (summary) => ProjectAgentGroupUnsupportedViewData(
              groupId: summary.groupId,
              displayName: summary.displayName,
              description: summary.description,
              reasonSummary: _unsupportedReasonTextService.buildSummary(
                summary.reasonCodes,
              ),
              reasonDetails: _unsupportedReasonTextService.buildDetails(
                summary.reasonCodes,
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _descriptionOf(OpeningSessionProjection projection) {
    final readiness = projection.orchestration.readiness;
    final currentGroupLabel = _displayTextPolicy.currentGroupLabel(
      projection.currentGroupDisplayName,
    );
    final currentGroupText =
        !_displayTextPolicy.hasResolvedGroup(currentGroupLabel)
        ? '当前项目还没有确定默认智能体组。'
        : '当前默认组：$currentGroupLabel。';
    final readinessText = projection.projectTypeId == 'long_novel'
        ? readiness.canStartLongTask
              ? '当前已满足长任务启动前的项目级组配置要求。'
              : '当前仍有部分项目开局信息需要继续补齐。'
        : readiness.canStartInteractiveSession
        ? '当前已满足进入普通协作会话前的项目级组配置要求。'
        : '当前仍有部分项目开局信息需要继续补齐。';
    return '$currentGroupText $readinessText';
  }
}
