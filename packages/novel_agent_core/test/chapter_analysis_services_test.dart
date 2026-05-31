import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chapter analysis services', () {
    final normalizer = ChapterAnalysisResultNormalizerService();
    final planBuilder = ChapterRewritePlanBuilderService();
    final taskFactory = ChapterRewriteTaskFactoryService();

    test(
      'normalizes chapter analysis result without leaking provider raw shape',
      () {
        // 中文注释: 这里验证分析结果会被收束成稳定领域对象，而不是继续暴露 provider 临时字段命名。
        final result = normalizer.normalizeResult(
          <String, Object?>{
            'review_type': 'plot',
            'title': '第一章剧情分析',
            'scope': 'chapters/ch01.md',
            'summary': '章节冲突建立较慢，后半段说明偏多。',
            'overall_assessment': '可读，但需要强化前半段推动力。',
            'issues': <Object?>[
              <String, Object?>{
                'title': '开局冲突太晚',
                'category': 'plot',
                'severity': 'high',
                'suggestion': '把收到短信的节点提前到前两段。',
                'source_path': 'chapters/ch01.md',
                'start_line': 1,
                'end_line': 18,
              },
            ],
            'suggestions': <Object?>[
              <String, Object?>{
                'title': '提前短信节点',
                'action_kind': 'partial',
                'summary': '把关键事件前移，尽快建立目标与悬念。',
                'issue_ids': <String>['analysis_ch01_issue_1'],
                'target_segments': <Object?>[
                  <String, Object?>{
                    'source_path': 'chapters/ch01.md',
                    'label': '开篇铺垫段',
                    'start_line': 1,
                    'end_line': 18,
                  },
                ],
              },
              '减少说明段，增加动作推进。',
            ],
          },
          generatedId: 'analysis_ch01',
          createdAt: '2026-05-25T10:00:00Z',
        );

        expect(result.id, 'analysis_ch01');
        expect(result.analysisType, 'plot');
        expect(result.chapterPath, 'chapters/ch01.md');
        expect(result.issues, hasLength(1));
        expect(result.suggestions, hasLength(2));
        expect(
          result.suggestions.first.actionKind,
          ChapterRewriteActionKind.rewritePartial,
        );
        expect(
          result.suggestions.last.actionKind,
          ChapterRewriteActionKind.rewriteFull,
        );
        expect(result.suggestions.first.targetSegments.single.startLine, 1);
      },
    );

    test('builds full partial and suggestions-only rewrite plans', () {
      final result = normalizer.normalizeResult(<String, Object?>{
        'review_type': 'style',
        'title': '第一章文风分析',
        'scope': 'chapters/ch01.md',
        'summary': '说明偏重，口吻略硬。',
        'issues': <Object?>[
          <String, Object?>{
            'id': 'issue_1',
            'title': '说明化表达偏多',
            'suggestion': '多用动作和对白承载信息。',
          },
        ],
        'suggestions': <Object?>[
          <String, Object?>{
            'id': 'suggestion_1',
            'title': '重写开篇三段',
            'action_kind': 'rewrite_partial',
            'target_segments': <Object?>[
              <String, Object?>{
                'id': 'segment_1',
                'source_path': 'chapters/ch01.md',
                'start_line': 1,
                'end_line': 12,
              },
            ],
          },
        ],
      }, generatedId: 'analysis_style_1');

      final fullPlan = planBuilder.buildFullChapterPlan(
        result,
        generatedId: 'plan_full_1',
      );
      final partialPlan = planBuilder.buildPartialRewritePlan(
        result,
        generatedId: 'plan_partial_1',
        targetSegments: result.suggestions.first.targetSegments,
        selectedSuggestionIds: const <String>['suggestion_1'],
      );
      final suggestionsOnlyPlan = planBuilder.buildSuggestionsOnlyPlan(
        result,
        generatedId: 'plan_advice_1',
      );

      expect(fullPlan.actionKind, ChapterRewriteActionKind.rewriteFull);
      expect(fullPlan.outputPaths, contains('chapters/ch01.md'));
      expect(partialPlan.actionKind, ChapterRewriteActionKind.rewritePartial);
      expect(partialPlan.targetSegments, hasLength(1));
      expect(partialPlan.instructions, contains('目标片段'));
      expect(
        suggestionsOnlyPlan.actionKind,
        ChapterRewriteActionKind.suggestionsOnly,
      );
      expect(suggestionsOnlyPlan.outputPaths, isEmpty);
    });

    test('turns rewrite plan and selected suggestions into revision tasks', () {
      final result = normalizer.normalizeResult(<String, Object?>{
        'review_type': 'continuity',
        'title': '第一章连续性分析',
        'scope': 'chapters/ch01.md',
        'summary': '角色心态转折过快。',
        'related_paths': <String>['assets/characters/protagonist.md'],
        'suggestions': <Object?>[
          <String, Object?>{
            'id': 'suggestion_1',
            'title': '补强心态过渡',
            'summary': '在冲突爆发前补一小段内心和观察。',
            'action_kind': 'rewrite_full',
            'output_paths': <String>['chapters/ch01.md'],
          },
        ],
      }, generatedId: 'analysis_cont_1');
      final plan = planBuilder.buildFullChapterPlan(
        result,
        generatedId: 'plan_cont_1',
        selectedSuggestionIds: const <String>['suggestion_1'],
      );

      final taskFromPlan = taskFactory.revisionTaskFromPlan(
        plan,
        analysisPath: 'analysis/ch01.continuity.analysis.json',
      );
      final taskFromSuggestions = taskFactory.revisionTaskFromSuggestions(
        result,
        result.suggestions,
        analysisPath: 'analysis/ch01.continuity.analysis.json',
      );

      expect(taskFromPlan, isNotNull);
      expect(taskFromPlan!['task_type'], 'revision');
      expect(
        ValueReaders.stringList(taskFromPlan['source_paths']),
        contains('analysis/ch01.continuity.analysis.json'),
      );
      expect(
        ValueReaders.mapValue(taskFromPlan['metadata'])['rewrite_action_kind'],
        ChapterRewriteActionKind.rewriteFull,
      );

      expect(taskFromSuggestions, isNotNull);
      expect(taskFromSuggestions!['task_type'], 'revision');
      expect(
        ValueReaders.mapValue(taskFromSuggestions['metadata'])['origin'],
        'chapter_analysis_suggestions',
      );
    });

    test(
      'does not create revision task directly for suggestions-only plan',
      () {
        final result = normalizer.normalizeResult(<String, Object?>{
          'review_type': 'general',
          'title': '第一章建议整理',
          'scope': 'chapters/ch01.md',
          'suggestions': <Object?>['把开头写得更抓人。'],
        }, generatedId: 'analysis_general_1');
        final plan = planBuilder.buildSuggestionsOnlyPlan(
          result,
          generatedId: 'plan_general_1',
        );

        expect(taskFactory.revisionTaskFromPlan(plan), isNull);
      },
    );
  });
}

