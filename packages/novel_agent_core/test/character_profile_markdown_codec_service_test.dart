import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CharacterProfile markdown codec', () {
    test('encodes and parses runtime snapshot fields', () {
      final codec = CharacterProfileMarkdownCodecService();
      final parser = CharacterProfileMarkdownParserService();
      const profile = CharacterProfile(
        id: 'hero_alpha',
        displayName: '林澈',
        summary: '主角，擅长观察。',
        currentStatus: '已抵达黑市',
        currentStateSummary: '他在黑市发现了与师门有关的异常线索。',
        latestStageLabel: '第4章后',
        latestUpdatedAt: '2026-05-26T10:00:00Z',
        latestSourcePaths: <String>['chapters/ch04.md'],
        storyRole: '主角',
      );

      final markdown = codec.encode(profile);
      final parsed = parser.parseDocument(
        markdown,
        fallbackId: 'fallback_id',
        relativePath: 'assets/characters/hero_alpha.md',
      );
      final normalized = const CharacterProfileNormalizerService().normalize(
        parsed,
      );

      expect(normalized.id, 'hero_alpha');
      expect(normalized.displayName, '林澈');
      expect(normalized.currentStatus, '已抵达黑市');
      expect(normalized.currentStateSummary, contains('黑市'));
      expect(normalized.latestStageLabel, '第4章后');
      expect(normalized.latestSourcePaths, <String>['chapters/ch04.md']);
    });
  });
}
