import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointReviewService', () {
    test(
      'builds checkpoint review with drift watch items and next actions',
      () {
        final service = LongTaskCheckpointReviewService(
          taskSummaryService: LongTaskTaskSummaryService(),
        );

        final review = service.buildReview(
          task: <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
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
            'changed_paths': <Object?>['chapters/ch01.md'],
            'chapter_length_evaluation': <String, Object?>{
              'current_length': 3100,
              'target_length': 2200,
              'preferred_min': 1800,
              'preferred_max': 2600,
              'level': 'needs_rebalance',
              'recommended_action': 'adjust_next_chapter',
              'notes': <Object?>[
                '当前章约 3100 字，目标基准约 2200 字。',
                '偏离尚可消化，建议在下一章优先回调分布，避免继续越拉越开。',
              ],
            },
            'response': <String, Object?>{
              'content': '已写出样章。',
              'tool_calls': <Object?>[
                <String, Object?>{'name': 'write_project_file'},
              ],
            },
          },
          memorySections: const <JsonMap>[
            <String, Object?>{'title': '风格锚点'},
            <String, Object?>{'title': '世界硬约束'},
            <String, Object?>{'title': '角色/身份锚点'},
          ],
          outputPaths: const <String>['chapters/ch01.md'],
          execution: <String, Object?>{
            'context_pack': <String, Object?>{
              'creative_rule_stack': <String, Object?>{
                'expression_constraints': <Object?>[
                  <String, Object?>{
                    'id': 'de_ai',
                    'display_name': '去 AI 风',
                    'summary': '降低模板化表达和解释腔。',
                    'kind': 'natural_expression',
                  },
                  <String, Object?>{
                    'id': 'strict_pov_boundary',
                    'display_name': '严格限知',
                    'summary': '严守 POV 信息边界。',
                    'kind': 'narrative_boundary',
                  },
                ],
              },
            },
          },
          createdAt: '2026-05-25T08:00:00Z',
        );

        expect(
          ValueReaders.stringList(review['drift_watch_items']),
          containsAll(<String>['样章阶段要重点检查文风是否稳定、入口是否干净利落。', '视角泄漏', '信息边界混用']),
        );
        expect(
          ValueReaders.mapList(
            review['drift_signals'],
          ).map((item) => ValueReaders.stringValue(item['domain'])),
          containsAll(<String>['style', 'world', 'entity']),
        );
        expect(
          ValueReaders.stringList(review['confirmation_focus']),
          contains('样章入口是否成立，是否能证明题材钩子和叙事方式可持续。'),
        );
        expect(
          ValueReaders.stringList(review['next_actions']),
          contains('样章通过后，确认是否继续正文队列或先修订风格与大纲。'),
        );
        expect(
          ValueReaders.mapValue(review['chapter_length_evaluation'])['level'],
          'needs_rebalance',
        );
        expect(
          ValueReaders.stringList(review['next_actions']),
          contains('下一章优先按章节字数基准回调，避免与前后章节继续拉开差距。'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              review['expression_constraint_review'],
            )['authenticity_pass_level'],
          ),
          'aggressive',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(review['narrative_supervisor_risk'])['overall'],
            )['category'],
          ),
          'accept',
        );
        expect(
          ValueReaders.stringList(review['mini_recheck_items']),
          contains('确认真实性清理后主角与关键说话者仍然保留各自声音。'),
        );
        final severity = LongTaskCheckpointSeverityService().assess(review);
        expect(ValueReaders.stringValue(severity['severity']), 'high');
      },
    );
  });
}
