import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskReviewRepairTaskService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskReviewRepairTaskService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_review_repair_task_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskReviewRepairTaskService(
        taskRepository: taskRepository,
        reviewReportService: ProjectReviewReportService(
          workspacePort: workspacePort,
          taskRepository: taskRepository,
        ),
      );
      project = ProjectDescriptor(
        id: 'review_repair_task_test',
        name: '审稿修复任务测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/continuity/ch01.md',
        '# 连续性检查：ch01\n\n- 范围：第01章\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/continuity/ch01.json',
        '''
{
  "id": "review_001",
  "title": "连续性检查：ch01",
  "review_type": "continuity",
  "scope": "第01章",
  "summary": "存在连续性问题。",
  "issues": [
    {
      "title": "设定前后矛盾",
      "suggestion": "统一誓约代价描述。"
    }
  ],
  "suggestions": ["统一世界规则。"],
  "review_contract": {
    "review_id": "review_001",
    "review_type": "continuity",
    "reviewer": {
      "reviewer_id": "reviewer-agent",
      "reviewer_role": "critic"
    },
    "basis": {
      "basis_type": "semantic_review",
      "summary": "第01章",
      "source_paths": ["chapters/ch01.md", "outline/总纲.md"],
      "target_paths": ["chapters/ch01.md"]
    },
    "findings": [
      {
        "finding_id": "finding_001",
        "severity": "blocking",
        "summary": "设定前后矛盾",
        "suggested_action": "统一誓约代价描述。",
        "evidence_paths": ["chapters/ch01.md"]
      }
    ],
    "risk_level": "critical",
    "recommended_disposition": "repair",
    "repair_brief": "统一誓约代价描述。",
    "summary": "存在连续性问题。",
    "evidence_paths": ["chapters/ch01.md"],
    "created_at": "2026-06-09T10:00:00Z"
  },
  "review_summary": {
    "review_id": "review_001",
    "review_type": "continuity",
    "reviewer_id": "reviewer-agent",
    "reviewer_role": "critic",
    "risk_level": "critical",
    "recommended_disposition": "repair",
    "finding_count": 1,
    "blocking_finding_count": 1,
    "summary": "存在连续性问题。",
    "repair_brief": "统一誓约代价描述。",
    "evidence_paths": ["chapters/ch01.md"]
  },
  "review_repair_handoff": {
    "action": "create_blocking_repair",
    "reason": "review_requests_blocking_repair",
    "blocks_main_flow": true,
    "requires_repair_task": true,
    "note": "存在连续性问题。",
    "repair_request": {
      "request_id": "repair_request_review_001",
      "source_review_id": "review_001",
      "source_review_type": "continuity",
      "source_disposition": "repair",
      "repair_brief": "统一誓约代价描述。",
      "finding_ids": ["finding_001"],
      "target_paths": ["chapters/ch01.md"],
      "context_paths": ["chapters/ch01.md", "outline/总纲.md"],
      "evidence_paths": ["chapters/ch01.md"],
      "blocks_main_flow": true
    }
  }
}
''',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('creates repair task from review task output and dedupes', () async {
      final first = await service.createTask(
        project: project,
        task: const <String, Object?>{
          'id': 'review_task_001',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'metadata': <String, Object?>{
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'runtime_baseline_id': 'chapter_collaboration_autorun',
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
            'checkpoint_review_path': 'tracking/checkpoint_reviews/sample.json',
          },
          'output_paths': <Object?>[
            'reviews/continuity/ch01.md',
            'reviews/continuity/ch01.json',
          ],
        },
      );

      expect(ValueReaders.boolValue(first['ok']), isTrue);
      expect(ValueReaders.boolValue(first['duplicated']), isFalse);
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(first['task'])['task_type'],
        ),
        'revision',
      );
      expect(
        ValueReaders.stringValue(ValueReaders.mapValue(first['task'])['mode']),
        TaskRuntimeConstants.modeSeedToFullNovel,
      );
      expect(
        ValueReaders.stringList(
          ValueReaders.mapValue(first['task'])['source_paths'],
        ),
        contains('tracking/modes/seed_autopilot_novel/guidance.md'),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(first['task'])['metadata'],
          )['origin'],
        ),
        'review_repair_handoff',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(first['task'])['metadata'],
          )['review_id'],
        ),
        'review_001',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(first['task'])['metadata'],
            )['review_repair_handoff'],
          )['action'],
        ),
        RepairHandoffActions.createBlockingRepair,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(first['task'])['metadata'],
          )['origin_checkpoint_review_path'],
        ),
        'tracking/checkpoint_reviews/sample.json',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(first['task'])['metadata'],
          )['runtime_baseline_id'],
        ),
        'chapter_collaboration_autorun',
      );
      expect(
        ValueReaders.stringList(
          ValueReaders.mapValue(first['task'])['depends_on'],
        ),
        contains('review_task_001'),
      );

      final second = await service.createTask(
        project: project,
        task: const <String, Object?>{
          'id': 'review_task_001',
          'task_type': 'review',
          'metadata': <String, Object?>{
            'checkpoint_review_path': 'tracking/checkpoint_reviews/sample.json',
          },
          'output_paths': <Object?>['reviews/continuity/ch01.md'],
        },
      );

      expect(ValueReaders.boolValue(second['ok']), isTrue);
      expect(ValueReaders.boolValue(second['duplicated']), isTrue);
    });

    test(
      'accepts json-first report path and resolves markdown sibling correctly',
      () async {
        final created = await service.createTask(
          project: project,
          task: const <String, Object?>{
            'id': 'review_task_002',
            'task_type': 'review',
            'output_paths': <Object?>[
              'reviews/continuity/ch01.json',
              'reviews/continuity/ch01.md',
            ],
          },
        );

        expect(ValueReaders.boolValue(created['ok']), isTrue);
        expect(
          ValueReaders.stringValue(created['review_report_path']),
          'reviews/continuity/ch01.md',
        );
      },
    );
  });
}
