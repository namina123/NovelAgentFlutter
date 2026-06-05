import '../models/opening_session_projection.dart';
import '../models/project_opening_maturity_assessment.dart';
import '../../presentation/models/opening_agent_group_option_view_data.dart';
import '../../presentation/models/opening_panel_view_data.dart';
import '../../presentation/models/opening_unsupported_group_view_data.dart';
import 'opening_unsupported_reason_text_service.dart';

class ConversationOpeningPanelViewDataService {
  const ConversationOpeningPanelViewDataService({
    OpeningUnsupportedReasonTextService? unsupportedReasonTextService,
  }) : _unsupportedReasonTextService =
           unsupportedReasonTextService ??
           const OpeningUnsupportedReasonTextService();

  final OpeningUnsupportedReasonTextService _unsupportedReasonTextService;

  OpeningPanelViewData? build(
    OpeningSessionProjection? projection,
    ProjectOpeningMaturityAssessment maturity,
  ) {
    // 中文注释: opening panel 视图数据独立从 projection 构建，避免控制器和 widget 自己拆 readiness 与组摘要。
    if (projection == null || !maturity.shouldShowOpeningEntry) {
      return null;
    }
    if (projection.groupSummaries.isEmpty &&
        projection.currentGroupDisplayName.trim().isEmpty) {
      return null;
    }
    return OpeningPanelViewData(
      title: '项目智能体组',
      summary: _summaryOf(projection),
      currentGroupDisplayName: projection.currentGroupDisplayName.trim(),
      selectionHint: '这里用于在开局阶段确认当前项目默认智能体组；进入正式会话后，会话层会单独决定当前使用的智能体。',
      supportedGroups: projection.supportedGroups
          .map(
            (summary) => OpeningAgentGroupOptionViewData(
              groupId: summary.groupId,
              displayName: summary.displayName,
              description: summary.description,
              isCurrent: summary.isCurrent,
              isDegraded: summary.isDegraded,
              isStarterGroup: summary.isStarterGroup,
            ),
          )
          .toList(growable: false),
      unsupportedGroups: projection.unsupportedGroups
          .map(
            (summary) => OpeningUnsupportedGroupViewData(
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

  String _summaryOf(OpeningSessionProjection projection) {
    final readiness = projection.orchestration.readiness;
    final visibleMissingRequirements = readiness.missingRequirements
        .where(
          (item) =>
              projection.projectTypeId == 'long_novel' ||
              item.id.trim() != 'conversation_goal',
        )
        .toList(growable: false);
    final currentGroupText = projection.currentGroupDisplayName.trim().isEmpty
        ? '当前还没有确定项目默认智能体组。'
        : '当前默认组：${projection.currentGroupDisplayName}。';
    final readinessText = projection.projectTypeId == 'long_novel'
        ? readiness.canStartLongTask
              ? '当前已可直接启动长任务。'
              : visibleMissingRequirements.isEmpty
              ? '当前仍需补充长任务开局信息。'
              : '仍需补充：${visibleMissingRequirements.map((item) => item.title).join('、')}。'
        : readiness.canStartInteractiveSession
        ? '当前已可直接进入协作对话。'
        : visibleMissingRequirements.isEmpty
        ? '可以直接输入你现在想写什么。'
        : '当前还需要确认：${visibleMissingRequirements.map((item) => item.title).join('、')}。';
    if (projection.derivedFromAgentBinding) {
      return '$currentGroupText 当前默认组来自旧项目智能体绑定，可在这里切换到正式项目组。 $readinessText';
    }
    return '$currentGroupText $readinessText';
  }
}
