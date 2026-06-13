import 'package:novel_agent_cli/commands/workflow/workflow_output_summary_service.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowOutputSummaryService', () {
    final service = WorkflowOutputSummaryService();

    test(
      'run center summary maps stop reason into human-readable diagnosis',
      () {
        final lines = service.runCenterBriefLines(const <String, Object?>{
          'status_label': '已暂停',
          'phase_label': '检查点',
          'reason': 'waiting_user_checkpoint',
          'recommended_action_label': '处理检查点',
        });

        expect(lines, contains('状态：已暂停'));
        expect(lines, contains('阶段：检查点'));
        expect(lines, contains('停止原因：等待用户确认（waiting_user_checkpoint）'));
        expect(lines, contains('下一步：处理检查点'));
      },
    );

    test(
      'narrative summary includes information counts signal and projection paths',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          <String, Object?>{
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
            '资料投影：knowledge/项目知识摘要.md | knowledge/设计元素摘要.md | research/资料研究摘要.md | references/引用作品边界.md',
          ),
        );
      },
    );

    test('information summary still shows human-readable zero-state lines', () {
      final contract = service.extractNarrativeRuntimeContract(
        const <String, Object?>{
          'changed_paths': <Object?>[],
          'checkpoint_review': <String, Object?>{'review': <String, Object?>{}},
        },
      );

      final lines = service.narrativeBriefLines(contract);

      expect(lines, contains('资料状态：无资料变更'));
      expect(lines, contains('当前没有新的资料状态变化。'));
      expect(
        lines,
        contains(
          '资料投影：knowledge/项目知识摘要.md | knowledge/设计元素摘要.md | research/资料研究摘要.md | references/引用作品边界.md',
        ),
      );
      expect(lines.any((line) => line.contains('payload')), isFalse);
    });

    test(
      'analysis information ids can backfill counts without changed paths',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          const <String, Object?>{
            'changed_paths': <Object?>[],
            'analysis_information': <String, Object?>{
              'knowledge_card_ids': <Object?>['knowledge-1', 'knowledge-2'],
              'design_element_ids': <Object?>['design-1'],
              'research_note_ids': <Object?>['research-1'],
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(lines, contains('资料状态：已执行研究'));
        expect(lines, contains('已执行资料研究，并更新相关资料摘要。'));
      },
    );

    test(
      'narrative summary shows expression constraint signals and chapter path diagnostics',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          <String, Object?>{
            'constraints': <String, Object?>{
              'present': true,
              'expression_constraint_active': true,
              'expression_constraint_policy_mode': 'adaptive',
              'expression_constraint_applied': true,
              'expression_constraint_review_required': true,
              'expression_constraint_review_provided': false,
              'expression_constraint_evidence_missing': true,
              'expression_constraint_violation_recorded': true,
              'expression_constraint_runtime_escalated': true,
              'review_suggested': true,
              'repair_required': false,
              'summary': '表达限制当前建议加强后续章节执行。',
              'expression_constraint_gate': <String, Object?>{
                'present': true,
                'adjust_next_chapter': true,
                'risk_signals': <Object?>['总而言之'],
              },
            },
            'expression_constraint_projection': <String, Object?>{
              'present': true,
              'status': 'suggest_strengthen',
              'status_label': '建议加强',
              'summary': '表达限制当前建议加强后续章节执行。',
              'policy_mode': 'adaptive',
              'active': true,
              'applied': true,
              'suggest_strengthen': true,
              'review_required': true,
              'review_provided': false,
              'evidence_missing': true,
              'runtime_escalated': true,
            },
            'chapter_delivery': <String, Object?>{
              'delivery_state': 'delivered',
              'chapter_path': 'chapters/第01章.md',
              'title': '第01章',
              'path_resolution': <String, Object?>{
                'requested_path': 'chapters/第01章_seed_to_full.md',
                'resolved_path': 'chapters/第01章.md',
                'path_changed': true,
                'reason': 'normalized_chapter_title',
                'title': '第01章',
              },
            },
            'stop_reason': 'waiting_user_checkpoint',
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{'summary': '章节已完成。'},
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(lines, contains('表达规则：建议加强（智能使用）'));
        expect(lines, contains('表达规则复核：缺少复核证据'));
        expect(lines, contains('表达规则处置：建议后续章节加强'));
        expect(lines, contains('表达规则信号：已记录风险信号（总而言之）'));
        expect(lines, contains('章节交付：已交付 | chapters/第01章.md'));
        expect(
          lines,
          contains(
            '路径诊断：请求 chapters/第01章_seed_to_full.md，已归一为 chapters/第01章.md',
          ),
        );
        expect(lines, contains('标题口径：第01章'));
        expect(lines, contains('停止原因：等待用户确认（waiting_user_checkpoint）'));
      },
    );

    test(
      'narrative summary prefers formal run center stop diagnosis over CLI-side reconstruction',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          const <String, Object?>{
            'run_center_contract': <String, Object?>{
              'stop_diagnosis': <String, Object?>{
                'present': true,
                'category': 'manual_attention',
                'code': 'delivery_manual_attention',
                'label': '内容质量关口',
                'summary': '当前运行需要先处理内容质量关口。',
              },
            },
            'stop_reason': 'waiting_user_checkpoint',
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{'summary': '章节已完成。'},
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(lines, contains('停止原因：内容质量关口（delivery_manual_attention）'));
        expect(
          lines,
          isNot(contains('停止原因：等待用户确认（waiting_user_checkpoint）')),
        );
      },
    );

    test(
      'narrative summary shows disabled expression constraint state cleanly',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          const <String, Object?>{
            'constraints': <String, Object?>{
              'present': true,
              'expression_constraint_active': true,
              'expression_constraint_policy_mode': 'disabled',
              'expression_constraint_disabled': true,
              'expression_constraint_applied': false,
              'expression_constraint_review_required': false,
              'expression_constraint_review_provided': false,
              'expression_constraint_evidence_missing': false,
              'summary': '表达限制当前已关闭。',
            },
            'expression_constraint_projection': <String, Object?>{
              'present': true,
              'status': 'disabled',
              'status_label': '已关闭',
              'summary': '表达限制当前已关闭。',
              'policy_mode': 'disabled',
              'active': true,
              'applied': false,
              'disabled': true,
            },
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{},
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(lines, contains('表达规则：已关闭（关闭）'));
        expect(lines, contains('表达规则处置：当前策略已关闭'));
      },
    );

    test(
      'narrative summary shows repair-required expression constraint state',
      () {
        final contract = service.extractNarrativeRuntimeContract(
          const <String, Object?>{
            'constraints': <String, Object?>{
              'present': true,
              'expression_constraint_active': true,
              'expression_constraint_policy_mode': 'force',
              'expression_constraint_applied': true,
              'expression_constraint_review_required': true,
              'expression_constraint_review_provided': true,
              'expression_constraint_violation_recorded': true,
              'repair_required': true,
              'summary': '表达限制当前要求先修订后再继续。',
              'expression_constraint_gate': <String, Object?>{
                'present': true,
                'repair_required': true,
                'risk_signals': <Object?>['视角泄漏'],
              },
            },
            'expression_constraint_projection': <String, Object?>{
              'present': true,
              'status': 'repair_blocked',
              'status_label': '阻塞修订',
              'summary': '表达限制当前要求先修订后再继续。',
              'policy_mode': 'force',
              'active': true,
              'applied': true,
              'blocks_repair': true,
              'review_required': true,
              'review_provided': true,
            },
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{},
            },
          },
        );

        final lines = service.narrativeBriefLines(contract);

        expect(lines, contains('表达规则：已阻塞修订（强力约束）'));
        expect(lines, contains('表达规则复核：已记录复核证据'));
        expect(lines, contains('表达规则处置：需要修补后再继续'));
        expect(lines, contains('表达规则信号：已记录风险信号（视角泄漏）'));
      },
    );

    test(
      'reference extraction summary uses production supervisor signal for coverage followup',
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

    test(
      'reference extraction summary surfaces mount wait and continuity review states',
      () {
        final lines = service.referenceExtractionBriefLines(
          const ProjectReferenceExtractionResult(
            runId: 'run_2',
            packageId: 'pkg_2',
            packageVersionId: 'v2',
            sourceFilePath: 'D:/reference.txt',
            sourceDecodeMode: 'utf8',
            groupResolutionKind: 'single_agent_fallback',
            selectedGroupId: 'reference_group',
            strategyProfileId: 'reference_extraction.standard',
            executionConcurrencyMode:
                ReferenceExtractionConcurrencyModes.single,
            proposalCount: 4,
            acceptedProposalCount: 2,
            finalizedEntryCount: 2,
            publishedSnapshotAvailable: true,
            attachToProjectRequested: true,
            projectMountedEntriesRequested: true,
            projectMountStatus: ProjectReferenceMountStatuses.denied,
            projectMountWarningCodes: <String>[
              'explicit_confirmation_required',
            ],
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
      },
    );
  });
}
