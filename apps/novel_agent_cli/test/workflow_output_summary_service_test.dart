import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_output_summary_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowOutputSummaryService', () {
    final service = WorkflowOutputSummaryService();

    test('still delegates run center rendering through the thin facade', () {
      final contract = service.extractRunCenterContract(const <String, Object?>{
        'record': <String, Object?>{
          'run_center_contract': <String, Object?>{
            'status_label': '已暂停',
            'phase_label': '检查点',
            'reason': 'waiting_user_checkpoint',
            'recommended_action_label': '处理检查点',
          },
        },
      });

      final lines = service.runCenterBriefLines(contract);

      expect(lines, contains('状态：已暂停'));
      expect(lines, contains('阶段：检查点'));
      expect(lines, contains('停止原因：等待用户确认（waiting_user_checkpoint）'));
      expect(lines, contains('下一步：处理检查点'));
    });

    test('still delegates narrative rendering through the thin facade', () {
      final contract = service.extractNarrativeRuntimeContract(
        const <String, Object?>{
          'changed_paths': <Object?>[
            '.novel_agent/information/knowledge_cards/knowledge-1.json',
            '.novel_agent/information/design_elements/design-1.json',
            '.novel_agent/information/research_notes/research-1.json',
            '.novel_agent/information/reference_works/reference-1.json',
            'knowledge/项目知识摘要.md',
            'knowledge/设计元素摘要.md',
            'research/资料研究摘要.md',
            'references/引用作品边界.md',
          ],
          'checkpoint_review': <String, Object?>{
            'review': <String, Object?>{
              'summary': '章节已完成。',
              'information_summary': '待研究 1 项，引用边界 1 项。',
            },
          },
        },
      );

      final lines = service.narrativeBriefLines(contract);

      expect(lines, contains('资料状态：已执行研究'));
      expect(lines, contains('待研究 1 项，引用边界 1 项。'));
      expect(
        lines,
        contains(
          '资料摘要：knowledge/项目知识摘要.md | knowledge/设计元素摘要.md | research/资料研究摘要.md | references/引用作品边界.md',
        ),
      );
    });

    test(
      'still delegates reference extraction rendering through the thin facade',
      () {
        final lines = service.referenceExtractionBriefLines(
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
      },
    );
  });
}
