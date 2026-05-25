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
          'output_paths': <Object?>['drafts/ch01.md'],
          'metadata': <String, Object?>{'stage': 'sample'},
        },
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_001',
          'relative_path': 'tracking/checkpoint_reviews/rev_001.json',
          'task_type': 'chapter',
          'stage': 'sample',
          'output_paths': <Object?>['drafts/ch01.md'],
          'drift_watch_items': <Object?>['检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。'],
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
            'drift_signals': <Object?>[
              <String, Object?>{
                'domain': 'entity',
                'severity': 'high',
                'title': '角色状态可能漂移',
                'note': '主角当前能力边界与前文锚点不稳。',
              },
            ],
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
  });
}
