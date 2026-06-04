import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWorkflowReviewRuntimeService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectWorkflowReviewRuntimeService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_workflow_review_runtime_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectWorkflowReviewRuntimeService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'workflow_review_runtime_test',
        name: 'Workflow Review Runtime Test',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'chapter_001',
        'title': '第01章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusSucceeded,
        'chapter': '第01章',
        'source_paths': <Object?>['outline/总纲.md'],
        'output_paths': <Object?>['chapters/ch01.md'],
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'persistent_context_paths': <Object?>['styles/default.md'],
        },
        'relative_path': 'tasks/chapter_001.json',
      });
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'gate_review_task_001',
        'title': '章级审稿：第01章',
        'task_type': 'review',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusQueued,
        'chapter': '第01章',
        'depends_on': <Object?>['chapter_001'],
        'source_paths': <Object?>['chapters/ch01.md', 'styles/default.md'],
        'output_paths': <Object?>[
          'reviews/general/ch01_gate.md',
          'reviews/general/ch01_gate.json',
        ],
        'metadata': <String, Object?>{
          'origin': 'chapter_gate_review',
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'review_type': 'general',
          'gate_source_task_id': 'chapter_001',
          'gate_source_task_path': 'tasks/chapter_001.json',
        },
        'relative_path': 'tasks/gate_review_task_001.json',
      });
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'chapter_002',
        'title': '第02章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusQueued,
        'depends_on': <Object?>['gate_review_task_001'],
        'output_paths': <Object?>['chapters/ch02.md'],
        'relative_path': 'tasks/chapter_002.json',
      });
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'preflight creates recovery task and rewires downstream when chapter body is missing',
      () async {
        final result = await service.preflightReviewTask(
          project: project,
          task: await taskRepository.loadTask(project, const <String, Object?>{
            'id': 'gate_review_task_001',
          }),
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['action']),
          'skip_review_create_recovery',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['delivery_state'])['state'],
          ),
          ChapterDeliveryStateStatuses.missingOutputRecoverable,
        );
        final recoveryTask = ValueReaders.mapValue(result['recovery_task']);
        expect(ValueReaders.stringValue(recoveryTask['task_type']), 'revision');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(recoveryTask['metadata'])['origin'],
          ),
          'chapter_gate_missing_output_recovery',
        );
        expect(
          ValueReaders.stringList(recoveryTask['depends_on']),
          contains('chapter_001'),
        );

        final chapterTwo = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002'},
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          contains(ValueReaders.stringValue(recoveryTask['id'])),
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          isNot(contains('gate_review_task_001')),
        );
      },
    );

    test(
      'persistSemanticReviewArtifacts appends repository review and mirrors report paths for gate workflow',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/ch01.md',
          '# 第01章\n\n正文已存在。',
        );
        final review = NarrativeSemanticReview(
          reviewId: 'semantic-review-1',
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.reviewer,
            sourceId: 'reviewer-agent',
          ),
          recommendedDisposition: SemanticReviewRecommendedDisposition.repair,
          summary: '存在需要返工的问题。',
          findings: const <SemanticReviewFinding>[
            SemanticReviewFinding(
              findingId: 'finding-1',
              severity: SemanticReviewSeverity.blocking,
              summary: '结尾推进与已知设定冲突。',
              suggestedAction: '统一誓约代价并重写结尾段落。',
              unableToLocateEvidence: true,
              unlocatableReason: '测试里只验证结构化持久化。',
            ),
          ],
        );

        final artifacts = await service.persistSemanticReviewArtifacts(
          project: project,
          task: await taskRepository.loadTask(project, const <String, Object?>{
            'id': 'gate_review_task_001',
          }),
          executedTools: <Object?>[
            <String, Object?>{
              'name': 'submit_semantic_review',
              'result': <String, Object?>{
                'domain_outcome': <String, Object?>{
                  'outcome_payload': <String, Object?>{
                    'review': review.toJson(),
                  },
                },
              },
            },
          ],
        );

        expect(ValueReaders.boolValue(artifacts['ok']), isTrue);
        expect(
          ValueReaders.stringList(artifacts['review_ids']),
          contains('semantic-review-1'),
        );
        final repoFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}reviews${Platform.pathSeparator}semantic-review-1.json',
        );
        final markdownFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}reviews${Platform.pathSeparator}general${Platform.pathSeparator}ch01_gate.md',
        );
        final jsonFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}reviews${Platform.pathSeparator}general${Platform.pathSeparator}ch01_gate.json',
        );
        expect(await repoFile.exists(), isTrue);
        expect(await markdownFile.exists(), isTrue);
        expect(await jsonFile.exists(), isTrue);

        final mirrored = await taskRepository.loadRecord(
          project,
          'reviews/general/ch01_gate.json',
        );
        expect(ValueReaders.stringValue(mirrored['id']), 'semantic-review-1');
        expect(ValueReaders.mapList(mirrored['issues']), hasLength(1));
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(mirrored['metadata'])['semantic_review_id'],
          ),
          'semantic-review-1',
        );
      },
    );
  });
}
