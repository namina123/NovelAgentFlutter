import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ForeshadowFeedbackSignalExtractorService', () {
    test(
      'extracts foreshadow feedback from analysis suggestion issue links',
      () {
        final service = ForeshadowFeedbackSignalExtractorService();

        final signals = service.fromAnalysisDocument(<String, Object?>{
          'id': 'analysis_01',
          'analysis_type': 'continuity',
          'chapter_path': 'chapters/ch01.md',
          'issues': <Object?>[
            <String, Object?>{
              'id': 'issue_seed',
              'title': '伏笔推进不足',
              'detail': '塔楼密钥已经出现，但没有继续强化风险。',
              'suggestion': '下一章要明确把它推进成待回收主线。',
              'related_foreshadow_ids': <Object?>['tower_key'],
              'related_timeline_ids': <Object?>['timeline_tower_key'],
              'related_relationship_ids': <Object?>['rel_master_apprentice'],
            },
          ],
          'suggestions': <Object?>[
            <String, Object?>{
              'id': 'suggestion_01',
              'title': '补强塔楼密钥线',
              'action_kind': 'rewrite_partial',
              'summary': '把塔楼密钥从埋设推进为待回收伏笔。',
              'issue_ids': <Object?>['issue_seed'],
              'output_paths': <Object?>['chapters/ch02.md'],
            },
          ],
        });

        expect(signals, hasLength(1));
        expect(signals.single.foreshadowId, 'tower_key');
        expect(
          signals.single.relatedTimelineIds,
          contains('timeline_tower_key'),
        );
        expect(
          signals.single.relatedRelationshipIds,
          contains('rel_master_apprentice'),
        );
        expect(signals.single.relatedPaths, contains('chapters/ch02.md'));
      },
    );
  });
}
