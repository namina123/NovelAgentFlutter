import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_opening_maturity_assessment_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/resource_entry_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'maturity service marks fresh project as opening stage when no authored files exist',
    () {
      const service = ProjectOpeningMaturityAssessmentService();

      final assessment = service.build(
        projectType: 'novel',
        resourceEntries: const <ResourceEntryViewData>[
          ResourceEntryViewData(
            id: 'premise',
            title: 'premise',
            relativePath: 'premise/',
            depth: 0,
            isDirectory: true,
          ),
        ],
        openingProjection: _projection(canStartInteractiveSession: false),
      );

      expect(assessment.stage, ProjectOpeningMaturityStage.openingInProgress);
      expect(assessment.shouldShowOpeningEntry, isTrue);
    },
  );

  test(
    'maturity service marks project as continue ready when narrative files already exist',
    () {
      const service = ProjectOpeningMaturityAssessmentService();

      final assessment = service.build(
        projectType: 'long_novel',
        resourceEntries: const <ResourceEntryViewData>[
          ResourceEntryViewData(
            id: 'outline_file',
            title: '总纲',
            relativePath: 'outlines/story/main_outline.md',
            depth: 1,
            isDirectory: false,
          ),
          ResourceEntryViewData(
            id: 'chapter_file',
            title: '第一章',
            relativePath: 'chapters/chapter_01.md',
            depth: 1,
            isDirectory: false,
          ),
        ],
        openingProjection: _projection(canStartInteractiveSession: false),
      );

      expect(assessment.stage, ProjectOpeningMaturityStage.continueReady);
      expect(assessment.shouldShowOpeningEntry, isFalse);
      expect(assessment.summary, contains('可直接继续推进长篇协作'));
    },
  );

  test(
    'maturity service uses full resource snapshot even when tree is collapsed',
    () {
      const service = ProjectOpeningMaturityAssessmentService();

      final assessment = service.build(
        projectType: 'long_novel',
        resourceEntries: const <ResourceEntryViewData>[
          ResourceEntryViewData(
            id: 'premise/project_brief.md',
            title: 'project_brief.md',
            relativePath: 'premise/project_brief.md',
            depth: 1,
            isDirectory: false,
          ),
          ResourceEntryViewData(
            id: 'outlines',
            title: 'outlines',
            relativePath: 'outlines',
            depth: 0,
            isDirectory: true,
          ),
        ],
        resourceSnapshotEntries: const <JsonMap>[
          <String, Object?>{
            'relative_path': 'premise/project_brief.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'outlines/story/总纲.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'outlines/chapters/章节任务清单.md',
            'is_dir': false,
          },
        ],
        openingProjection: _projection(canStartInteractiveSession: false),
      );

      expect(assessment.stage, ProjectOpeningMaturityStage.continueReady);
      expect(assessment.shouldShowOpeningEntry, isFalse);
    },
  );
}

OpeningSessionProjection _projection({
  required bool canStartInteractiveSession,
}) {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_generalist',
    currentGroupDisplayName: '默认小说开局',
    groupSummaries: const [],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'novel',
        status: OpeningSessionState.statusCollecting,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_novel_generalist',
          availableAgentGroupIds: <String>['starter_novel_generalist'],
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-28T00:00:00.000',
        updatedAt: '2026-05-28T00:00:00.000',
      ),
      readiness: OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: canStartInteractiveSession,
        missingRequirements: const <OpeningMissingRequirement>[
          OpeningMissingRequirement(
            id: 'conversation_goal',
            title: '缺少本次目标',
            description: '请先确定会话目标。',
          ),
        ],
      ),
      suggestedActions: const <OpeningSuggestedAction>[],
    ),
  );
}
