import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_assessment.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_opening_panel_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationOpeningPanelViewDataService', () {
    test('builds supported and unsupported groups for long-task opening', () {
      const service = ConversationOpeningPanelViewDataService();

      final viewData = service.build(
        OpeningSessionProjection(
          projectTypeId: 'long_novel',
          currentGroupId: 'starter_long_task',
          currentGroupDisplayName: '长篇总控组',
          groupSummaries: const [
            OpeningAgentGroupSummary(
              groupId: 'starter_long_task',
              displayName: '长篇总控组',
              description: '负责长篇开局与节奏收束。',
              isSupported: true,
              isDegraded: false,
              isCurrent: true,
              isStarterGroup: true,
            ),
            OpeningAgentGroupSummary(
              groupId: 'deconstruction',
              displayName: '拆书组',
              description: '只适用于拆书项目。',
              isSupported: false,
              isDegraded: false,
              isCurrent: false,
              isStarterGroup: false,
              reasonCodes: ['projectTypeMismatch'],
            ),
          ],
          orchestration: OpeningOrchestrationResult(
            state: const OpeningSessionState(
              projectTypeId: 'long_novel',
              status: OpeningSessionState.statusCollecting,
              intent: OpeningIntentSnapshot(
                resolvedAgentGroupId: 'starter_long_task',
                runtimeBaselineId: 'chapter_collaboration_autorun',
              ),
              stageRecords: [],
              createdAt: '2026-05-27T00:00:00Z',
              updatedAt: '2026-05-27T00:00:00Z',
            ),
            readiness: const OpeningReadinessAssessment(
              canStartLongTask: false,
              canStartInteractiveSession: false,
              missingRequirements: [
                OpeningMissingRequirement(
                  id: 'mode_guidance',
                  title: '模式引导',
                  description: '还需要先完成模式引导。',
                ),
              ],
            ),
            suggestedActions: const [],
          ),
        ),
        const ProjectOpeningMaturityAssessment(
          stage: ProjectOpeningMaturityStage.openingInProgress,
          summary: '当前项目仍处于开局整理阶段，先补齐少量信息再继续。',
          authoredFoundationFileCount: 0,
          narrativeFileCount: 0,
        ),
      );

      expect(viewData, isNotNull);
      expect(viewData!.supportedGroups, hasLength(1));
      expect(viewData.unsupportedGroups, hasLength(1));
      expect(viewData.currentGroupDisplayName, '长篇总控组');
      expect(viewData.summary, contains('仍需补充：模式引导'));
      expect(
        viewData.unsupportedGroups.single.reasonSummary,
        '项目类型与该智能体组的适用范围不匹配。',
      );
    });

    test('hides panel for grounded project', () {
      const service = ConversationOpeningPanelViewDataService();

      final viewData = service.build(
        OpeningSessionProjection(
          projectTypeId: 'novel',
          currentGroupId: 'starter_novel_generalist',
          currentGroupDisplayName: '默认小说开局',
          groupSummaries: const [
            OpeningAgentGroupSummary(
              groupId: 'starter_novel_generalist',
              displayName: '默认小说开局',
              description: '默认小说开局',
              isSupported: true,
              isDegraded: false,
              isCurrent: true,
              isStarterGroup: true,
            ),
          ],
          orchestration: OpeningOrchestrationResult(
            state: const OpeningSessionState(
              projectTypeId: 'novel',
              status: OpeningSessionState.statusReadyForInteractiveSession,
              intent: OpeningIntentSnapshot(
                resolvedAgentGroupId: 'starter_novel_generalist',
              ),
              stageRecords: [],
              createdAt: '2026-05-27T00:00:00Z',
              updatedAt: '2026-05-27T00:00:00Z',
            ),
            readiness: const OpeningReadinessAssessment(
              canStartLongTask: false,
              canStartInteractiveSession: true,
              missingRequirements: [],
            ),
            suggestedActions: const [],
          ),
        ),
        const ProjectOpeningMaturityAssessment(
          stage: ProjectOpeningMaturityStage.continueReady,
          summary: '当前项目已经有正文或结构基础，可直接继续创作。',
          authoredFoundationFileCount: 2,
          narrativeFileCount: 1,
        ),
      );

      expect(viewData, isNull);
    });
  });
}
