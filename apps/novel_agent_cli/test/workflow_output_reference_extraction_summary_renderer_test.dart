import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_output_reference_extraction_summary_renderer.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionSummaryRenderer', () {
    final renderer = ReferenceExtractionSummaryRenderer();

    test(
      'renders follow-up coverage and projection summary from production result',
      () {
        final lines = renderer.renderLines(
          const ProjectReferenceExtractionResult(
            runId: 'run_1',
            packageId: 'pkg_1',
            packageVersionId: 'v1',
            sourceFilePath: 'D:/reference.txt',
            sourceDecodeMode: 'utf8',
            groupResolutionKind: 'single_agent_fallback',
            selectedGroupId: 'reference_group',
            strategyProfileId: 'reference_extraction.standard',
            executionConcurrencyMode:
                ReferenceExtractionConcurrencyModes.single,
            proposalCount: 12,
            acceptedProposalCount: 4,
            finalizedEntryCount: 8,
            batchCount: 3,
            completedBatchCount: 2,
            batchCoverageRatio: 0.67,
            needsContinuation: true,
            coverageRequiresFollowup: true,
            uncoveredCoverageDimensionIds: <String>['fact.1', 'fact.2'],
            followupSegmentIds: <String>['segment_3'],
            publishedSnapshotAvailable: false,
            attachToProjectRequested: true,
            projectMountedEntriesRequested: true,
            projectMountStatus: ProjectReferenceMountStatuses.applied,
            knowledgeCardIds: <String>['knowledge_1'],
            designElementIds: <String>['design_1'],
            researchNoteIds: <String>['research_1'],
            referenceWorkIds: <String>['reference_1'],
            generatedProjectionPaths: <String>[
              'knowledge/项目知识摘要.md',
              'research/资料研究摘要.md',
            ],
          ),
          strategyLabel: '标准提取 (reference_extraction.standard)',
        );

        expect(lines, contains('控制面：覆盖未完成'));
        expect(
          lines,
          contains('停止原因：覆盖不足，需继续提取（reference_coverage_followup_required）'),
        );
        expect(lines, contains('策略：标准提取 (reference_extraction.standard)'));
        expect(lines, contains('资料包：pkg_1@v1'));
        expect(
          lines,
          contains(
            '覆盖：批次 2/3 完成 | coverage 67% | 待补覆盖 2 维 | followup segment 1 段',
          ),
        );
        expect(lines, contains('挂载：已挂载到项目 | 投影 2 个'));
        expect(lines, contains('连续性：当前无连续性冲突或 review alert'));
        expect(
          lines,
          contains('资料产物：knowledge 1 | design 1 | research 1 | reference 1'),
        );
        expect(lines, contains('轻投影：knowledge/项目知识摘要.md | research/资料研究摘要.md'));
      },
    );

    test('renders mount confirmation and continuity review states', () {
      final lines = renderer.renderLines(
        const ProjectReferenceExtractionResult(
          runId: 'run_2',
          packageId: 'pkg_2',
          packageVersionId: 'v2',
          sourceFilePath: 'D:/reference.txt',
          sourceDecodeMode: 'utf8',
          groupResolutionKind: 'single_agent_fallback',
          selectedGroupId: 'reference_group',
          strategyProfileId: 'reference_extraction.standard',
          executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
          proposalCount: 4,
          acceptedProposalCount: 2,
          finalizedEntryCount: 2,
          publishedSnapshotAvailable: true,
          attachToProjectRequested: true,
          projectMountedEntriesRequested: true,
          projectMountStatus: ProjectReferenceMountStatuses.denied,
          projectMountWarningCodes: <String>['explicit_confirmation_required'],
          conflictClusterCount: 2,
          canonDecisionCount: 1,
          reviewAlertCount: 1,
          requiresManualContinuityReview: true,
          unresolvedConflictCount: 1,
        ),
      );

      expect(lines, contains('控制面：挂载等待确认'));
      expect(
        lines,
        contains('停止原因：挂载需要显式确认（reference_mount_confirmation_required）'),
      );
      expect(
        lines,
        contains('挂载：等待挂载确认 | warning: explicit_confirmation_required'),
      );
      expect(
        lines,
        contains('连续性：conflicts 2 | decisions 1 | alerts 1 | 需人工复核 | 未决 1'),
      );
    });
  });
}
