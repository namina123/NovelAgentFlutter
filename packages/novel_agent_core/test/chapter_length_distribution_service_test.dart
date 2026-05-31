import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Chapter length distribution services', () {
    test('resolves sample override and normalized metadata', () {
      // 中文注释: 这里验证 loose options 会被归一化成标准 profile/policy，并保留旧字段兼容。
      const resolver = ChapterLengthProfileResolverService();

      final metadata = resolver.buildMetadataFromOptions(
        const <String, Object?>{
          'enable_chapter_word_constraints': true,
          'chapter_word_target': 2200,
          'chapter_word_min': 1800,
          'chapter_word_max': 2600,
          'sample_chapter_word_target': 1500,
        },
        stage: 'sample',
      );
      final profile = ValueReaders.mapValue(metadata['chapter_length_profile']);

      expect(ValueReaders.intValue(metadata['chapter_word_target']), 1500);
      expect(ValueReaders.intValue(profile['target_length']), 1500);
      expect(ValueReaders.stringValue(profile['stage']), 'sample');
      expect(
        ValueReaders.intValue(
          ValueReaders.mapValue(
            metadata['chapter_length_distribution_policy'],
          )['rolling_window'],
        ),
        4,
      );
    });

    test('evaluates chapter length as severe when target and adjacency drift are large', () {
      // 中文注释: 这里验证严重偏离时会进入 review_or_repair，而不是只给轻提醒。
      const service = ChapterLengthDistributionService();
      const profile = ChapterLengthProfile(
        enabled: true,
        targetLength: 2200,
        preferredMin: 1800,
        preferredMax: 2600,
        stage: 'draft',
      );
      const policy = ChapterLengthDistributionPolicy();

      final evaluation = service.evaluate(
        profile: profile,
        policy: policy,
        currentRecord: const ChapterLengthRecord(
          length: 3600,
          sortOrder: 4,
          relativePath: 'chapters/ch04.md',
        ),
        history: const <ChapterLengthRecord>[
          ChapterLengthRecord(length: 2100, sortOrder: 1),
          ChapterLengthRecord(length: 2250, sortOrder: 2),
          ChapterLengthRecord(length: 2180, sortOrder: 3),
        ],
      );

      expect(evaluation.level, 'severely_off');
      expect(evaluation.recommendedAction, 'review_or_repair');
      expect(evaluation.notes.join('\n'), contains('偏离已经明显'));
    });

    test('evaluates chapter length as balanced when recent distribution is stable', () {
      // 中文注释: 这里验证正常分布不会被误判成需要返工，最多保留稳定通过结果。
      const service = ChapterLengthDistributionService();
      const profile = ChapterLengthProfile(
        enabled: true,
        targetLength: 2200,
        preferredMin: 1800,
        preferredMax: 2600,
        stage: 'draft',
      );

      final evaluation = service.evaluate(
        profile: profile,
        policy: const ChapterLengthDistributionPolicy(),
        currentRecord: const ChapterLengthRecord(length: 2280, sortOrder: 4),
        history: const <ChapterLengthRecord>[
          ChapterLengthRecord(length: 2150, sortOrder: 1),
          ChapterLengthRecord(length: 2210, sortOrder: 2),
          ChapterLengthRecord(length: 2300, sortOrder: 3),
        ],
      );

      expect(evaluation.level, 'balanced');
      expect(evaluation.recommendedAction, 'pass');
    });
  });
}
