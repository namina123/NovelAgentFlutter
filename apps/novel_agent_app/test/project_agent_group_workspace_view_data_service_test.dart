import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_agent_group_workspace_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const service = ProjectAgentGroupWorkspaceViewDataService();

  test(
    'builds project-level overlay data with supported and unsupported groups',
    () {
      final viewData = service.build(
        projection: OpeningSessionProjection(
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
              status: OpeningSessionState.statusReadyForLongTask,
              intent: OpeningIntentSnapshot(
                resolvedAgentGroupId: 'starter_long_task',
                availableAgentGroupIds: ['starter_long_task', 'deconstruction'],
              ),
              stageRecords: [],
              createdAt: '2026-05-28T00:00:00Z',
              updatedAt: '2026-05-28T00:00:00Z',
            ),
            readiness: const OpeningReadinessAssessment(
              canStartLongTask: true,
              canStartInteractiveSession: true,
              missingRequirements: [],
            ),
            suggestedActions: const [],
          ),
          currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
            agentId: 'default_generalist',
            displayName: '综合创作智能体',
            role: '负责统筹当前长篇协作。',
            thinkingSupported: true,
          ),
        ),
      );

      expect(viewData.title, '项目智能体组');
      expect(viewData.currentGroupLabel, '长篇总控组');
      expect(viewData.primaryAgentLabel, '综合创作智能体');
      expect(viewData.selectionHint, '这里用于设置当前项目的默认协作组。');
      expect(viewData.supportedGroups, hasLength(1));
      expect(viewData.supportedGroups.single.groupId, 'starter_long_task');
      expect(viewData.unsupportedGroups, hasLength(1));
      expect(
        viewData.unsupportedGroups.single.reasonSummary,
        '项目类型与该智能体组的适用范围不匹配。',
      );
      expect(viewData.description, contains('当前默认组：长篇总控组。'));
      expect(viewData.description, contains('当前已满足长任务启动前的项目级组配置要求。'));
    },
  );
}
