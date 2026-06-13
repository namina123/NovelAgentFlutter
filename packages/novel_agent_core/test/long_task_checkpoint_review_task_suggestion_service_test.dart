import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointReviewTaskSuggestionService', () {
    test('builds chapter review suggestions for sample draft outputs', () {
      final service = LongTaskCheckpointReviewTaskSuggestionService();

      final suggestions = service.buildSuggestions(
        task: const <String, Object?>{
          'id': 'chapter_001',
          'task_type': 'chapter',
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{'stage': 'sample'},
        },
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_001',
          'relative_path': 'tracking/checkpoint_reviews/rev_001.json',
          'task_type': 'chapter',
          'stage': 'sample',
          'output_paths': <Object?>['chapters/ch01.md'],
          'drift_watch_items': <Object?>['检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。'],
          'expression_constraint_review': <String, Object?>{
            'authenticity_pass_level': 'aggressive',
            'review_focuses': <Object?>['重点清理 AI 味、假深刻句、总结腔与解释腔，但不能洗平人物声音。'],
            'mini_recheck_items': <Object?>['确认真实性清理后主角与关键说话者仍然保留各自声音。'],
          },
        },
      );

      expect(suggestions, hasLength(3));
      expect(
        ValueReaders.stringValue(suggestions.first['review_type']),
        'style',
      );
      expect(ValueReaders.intValue(suggestions.first['priority_rank']), 1);
      expect(
        suggestions.map(
          (item) => ValueReaders.stringValue(item['review_type']),
        ),
        containsAll(<String>['continuity', 'plot', 'style']),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            suggestions.first['metadata'],
          )['checkpoint_review_id'],
        ),
        'checkpoint_review_001',
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            suggestions.first['metadata'],
          )['priority_reason'],
        ),
        contains('文风漂移'),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            suggestions.first['metadata'],
          )['authenticity_pass_level'],
        ),
        'aggressive',
      );
    });

    test('builds planning review suggestions for outline and specs outputs', () {
      final service = LongTaskCheckpointReviewTaskSuggestionService();

      final suggestions = service.buildSuggestions(
        task: const <String, Object?>{
          'id': 'planning_001',
          'task_type': 'planning',
          'output_paths': <Object?>['outline/main.md', 'specs/project_spec.md'],
        },
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_002',
          'task_type': 'planning',
          'output_paths': <Object?>['outline/main.md', 'specs/project_spec.md'],
        },
      );

      final pairs = suggestions
          .map(
            (item) =>
                '${ValueReaders.stringValue(item['source_path'])}:${ValueReaders.stringValue(item['review_type'])}',
          )
          .toList(growable: false);
      expect(pairs, contains('outline/main.md:plot'));
      expect(pairs, contains('specs/project_spec.md:plot'));
      expect(pairs, contains('specs/project_spec.md:continuity'));
    });

    test(
      'planning review suggestions ignore task and sidecar outputs and keep canonical planning artifacts',
      () {
        final service = LongTaskCheckpointReviewTaskSuggestionService();

        final suggestions = service.buildSuggestions(
          task: const <String, Object?>{
            'id': 'planning_002',
            'task_type': 'planning',
            'output_paths': <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
              'tasks/plan_seed_to_full_novel_001_chapter_001_task.json',
              'tracking/checkpoint_reviews/planning_002.json',
              'world/清溪镇.md',
              'assets/characters/主角.md',
            ],
          },
          checkpointReview: const <String, Object?>{
            'id': 'checkpoint_review_002b',
            'task_type': 'planning',
            'output_paths': <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
              'tasks/plan_seed_to_full_novel_001_chapter_001_task.json',
              'tracking/checkpoint_reviews/planning_002.json',
              'world/清溪镇.md',
              'assets/characters/主角.md',
            ],
          },
        );

        final sourcePaths = suggestions
            .map((item) => ValueReaders.stringValue(item['source_path']))
            .toSet();
        expect(
          sourcePaths,
          equals(<String>{
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          }),
        );
        expect(
          suggestions.any(
            (item) =>
                ValueReaders.stringValue(item['source_path'])
                    .startsWith('tasks/'),
          ),
          isFalse,
        );
      },
    );

    test(
      'world or entity drift can inject continuity review for outline outputs',
      () {
        final service = LongTaskCheckpointReviewTaskSuggestionService();

        final suggestions = service.buildSuggestions(
          task: const <String, Object?>{
            'id': 'planning_003',
            'task_type': 'planning',
            'output_paths': <Object?>['outline/main.md'],
          },
          checkpointReview: const <String, Object?>{
            'id': 'checkpoint_review_003',
            'task_type': 'planning',
            'output_paths': <Object?>['outline/main.md'],
            'expression_constraint_review': <String, Object?>{
              'continuity_watch_items': <Object?>['视角泄漏', '设定状态漂移'],
            },
          },
        );

        expect(
          suggestions.map(
            (item) =>
                '${ValueReaders.stringValue(item['source_path'])}:${ValueReaders.stringValue(item['review_type'])}',
          ),
          contains('outline/main.md:continuity'),
        );
      },
    );

    test('does not recurse followup review suggestions from review tasks', () {
      final service = LongTaskCheckpointReviewTaskSuggestionService();

      final suggestions = service.buildSuggestions(
        task: const <String, Object?>{
          'id': 'review_001',
          'task_type': 'review',
          'output_paths': <Object?>['reviews/plot/ch01.md'],
          'metadata': <String, Object?>{
            'origin': 'checkpoint_review_suggestion',
            'stage': 'sample',
          },
        },
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_review_001',
          'task_type': 'review',
          'stage': 'sample',
          'output_paths': <Object?>['reviews/plot/ch01.md'],
        },
      );

      expect(suggestions, isEmpty);
    });
  });
}
