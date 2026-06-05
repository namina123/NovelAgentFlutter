import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskCheckpointReviewService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskCheckpointReviewService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_checkpoint_review_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskCheckpointReviewService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'checkpoint_review_test',
        name: '检查点复盘测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await taskRepository.writeTextFile(
        project,
        'chapters/ch01.md',
        '# 第01章\n\n样章正文',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves checkpoint review json and markdown', () async {
      final saved = await service.saveReview(
        project: project,
        task: <String, Object?>{
          'id': 'chapter_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{
            'stage': 'sample',
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
          },
        },
        result: <String, Object?>{
          'ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'changed_paths': <Object?>[
            'chapters/ch01.md',
            '.novel_agent/information/research_requests/research_request_writer_1.json',
          ],
          'executed_tools': <Object?>[
            <String, Object?>{
              'name': 'request_external_research',
              'result': <String, Object?>{
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'request_registered': true,
                    'network_execution_performed': false,
                    'research_request': <String, Object?>{
                      'query': '样章入口相关资料',
                    },
                  },
                },
              },
            },
          ],
          'response': <String, Object?>{'content': '已写出样章。'},
        },
        memorySections: const <JsonMap>[
          <String, Object?>{'title': '风格锚点'},
        ],
        execution: const <String, Object?>{
          'activation_report': <String, Object?>{
            'items': <Object?>[
              <String, Object?>{
                'title': '轮回规则',
                'omitted': true,
                'metadata': <String, Object?>{
                  'source_kind': 'project_knowledge_card',
                  'required': true,
                },
              },
            ],
          },
          'context_pack': <String, Object?>{
            'creative_rule_stack': <String, Object?>{
              'expression_constraints': <Object?>[
                <String, Object?>{
                  'id': 'de_ai',
                  'display_name': '去 AI 风',
                  'summary': '降低模板化表达和解释腔。',
                  'kind': 'natural_expression',
                },
              ],
            },
          },
        },
      );

      expect(ValueReaders.boolValue(saved['ok']), isTrue);
      expect(
        ValueReaders.stringValue(saved['relative_path']),
        startsWith('tracking/checkpoint_reviews/'),
      );
      expect(ValueReaders.stringValue(saved['markdown_path']), endsWith('.md'));
      final review = ValueReaders.mapValue(saved['review']);
      expect(ValueReaders.mapList(review['output_excerpts']), isNotEmpty);
      expect(ValueReaders.stringValue(review['severity']), isNotEmpty);
      expect(ValueReaders.mapList(review['suggested_actions']), isNotEmpty);
      expect(ValueReaders.stringValue(review['action_summary']), isNotEmpty);
      expect(ValueReaders.mapValue(review['disposition']), isNotEmpty);
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            review['expression_constraint_review'],
          )['authenticity_pass_level'],
        ),
        'aggressive',
      );
      expect(
        ValueReaders.stringValue(review['continuation_disposition']),
        isNotEmpty,
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(review['information_signal'])['category'],
        ),
        'repair',
      );
      expect(
        ValueReaders.stringValue(review['information_summary']),
        contains('待研究 1 项'),
      );
      final markdownContent = await taskRepository.readTextFile(
        project,
        ValueReaders.stringValue(saved['markdown_path']),
      );
      expect(markdownContent, contains('## Information 信号'));
      expect(markdownContent, contains('Required 信息省略'));
    });
  });
}
