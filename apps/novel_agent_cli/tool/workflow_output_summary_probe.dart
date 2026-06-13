import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/commands/workflow/workflow_output_summary_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  final service = WorkflowOutputSummaryService();
  final contract = service.extractRunCenterContract(const <String, Object?>{
    'long_task_run_center_contract': <String, Object?>{
      'status_label': '已暂停',
      'phase_label': '已暂停',
      'reason': 'manual_pause',
      'recommended_action_label': '继续运行',
      'progress': <String, Object?>{'overall_percent': 42},
      'active_task': <String, Object?>{'title': '第 8 章'},
      'resume_brief': <String, Object?>{
        'resume_title': '长任务已暂停',
        'resume_summary': '当前运行被手动暂停，主链不会继续推进，直到你主动恢复。',
        'last_step_summary': '最近停在：第 8 章（tasks/ch08.json）',
        'next_action_summary': '建议下一步：继续运行',
      },
    },
  });
  final lines = service.runCenterBriefLines(contract);
  final expected = <String>[
    '状态：已暂停',
    '阶段：已暂停',
    '进度：42%',
    '当前任务：第 8 章',
    '停止原因：manual_pause',
    '下一步：继续运行',
    '恢复标题：长任务已暂停',
  ];
  for (final item in expected) {
    if (!lines.contains(item)) {
      stderr.writeln('workflow_output_summary_probe: missing line -> $item');
      stderr.writeln(lines.join('\n'));
      exitCode = 1;
      return;
    }
  }
  final narrativeContract = service.extractNarrativeRuntimeContract(
    const <String, Object?>{
      'activation_report_path':
          'tracking/chapter_atomic/ch01.activation_report.json',
      'activation_report_summary': 'selected 8, omitted 2, files 8.',
      'chapter_delivery_state': 'delivered',
      'chapter_delivery_path': 'chapters/ch01.md',
      'checkpoint_review': <String, Object?>{
        'relative_path': 'tracking/checkpoint_reviews/ch01.json',
        'review': <String, Object?>{'summary': '当前章已通过检查点复核。'},
      },
      'changed_paths': <Object?>[
        '.novel_agent/continuity/ledgers/main-ledger/entries.jsonl',
        '.novel_agent/continuity/reviews/review-001.json',
        '.novel_agent/continuity/deliveries/delivery-001.json',
      ],
    },
  );
  final narrativeLines = service.narrativeBriefLines(narrativeContract);
  final narrativeExpected = <String>[
    'Activation：selected 8, omitted 2, files 8.',
    'Delivery：delivered | chapters/ch01.md',
    'Review：当前章已通过检查点复核。',
    'Continuity：ledger 1 | reviews 1 | deliveries 1',
  ];
  for (final item in narrativeExpected) {
    if (!narrativeLines.contains(item)) {
      stderr.writeln(
        'workflow_output_summary_probe: missing narrative line -> $item',
      );
      stderr.writeln(narrativeLines.join('\n'));
      exitCode = 1;
      return;
    }
  }
  final referenceLines = service.referenceExtractionBriefLines(
    const ProjectReferenceExtractionResult(
      runId: 'reference_run_1',
      packageId: 'hp_volume1',
      packageVersionId: 'v20260609',
      sourceFilePath: 'D:/reference_source.txt',
      sourceDecodeMode: 'utf8',
      groupResolutionKind: 'single_agent_fallback',
      selectedGroupId: 'reference_extraction_group',
      strategyProfileId: 'reference_extraction.standard',
      executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
      proposalCount: 12,
      acceptedProposalCount: 5,
      finalizedEntryCount: 9,
      batchCount: 4,
      completedBatchCount: 4,
      batchCoverageRatio: 1.0,
      runStatus: ReferenceExtractionRunStatuses.completedPublishable,
      publishedSnapshotAvailable: true,
      attachToProjectRequested: true,
      projectMountedEntriesRequested: true,
      projectMountStatus: ProjectReferenceMountStatuses.applied,
      conflictClusterCount: 1,
      canonDecisionCount: 1,
      reviewAlertCount: 0,
      knowledgeCardIds: <String>['knowledge_1'],
      researchNoteIds: <String>['research_1'],
      referenceWorkIds: <String>['reference_1'],
      generatedProjectionPaths: <String>[
        'knowledge/项目知识摘要.md',
        'references/引用作品边界.md',
      ],
    ),
    strategyLabel: '标准提取 (reference_extraction.standard)',
  );
  final referenceExpected = <String>[
    '控制面：已完成',
    '停止原因：publishable 结果已完成（completed_publishable）',
    '挂载：已挂载到项目 | 投影 2 个',
    '连续性：conflicts 1 | decisions 1 | alerts 0',
    '轻投影：knowledge/项目知识摘要.md | references/引用作品边界.md',
  ];
  for (final item in referenceExpected) {
    if (!referenceLines.contains(item)) {
      stderr.writeln(
        'workflow_output_summary_probe: missing reference line -> $item',
      );
      stderr.writeln(referenceLines.join('\n'));
      exitCode = 1;
      return;
    }
  }
  stdout.writeln('workflow_output_summary_probe: PASS');
}
