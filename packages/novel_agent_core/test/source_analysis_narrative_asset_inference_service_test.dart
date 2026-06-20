import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SourceAnalysisNarrativeAssetInferenceService', () {
    const service = SourceAnalysisNarrativeAssetInferenceService();

    test('infers reusable narrative asset hints from source text and chapter summaries', () {
      final chapterSummaries = <SourceAnalysisChapterSummary>[
        const SourceAnalysisChapterSummary(
          sequence: 1,
          title: '第一章 港口风暴',
          summary: '林砚在港口撞见黑潮议会的密使，预感更大的追捕就要开始。',
        ),
        const SourceAnalysisChapterSummary(
          sequence: 2,
          title: '第二章 议会阴影',
          summary: '林砚与议长正面交锋，让黑潮议会的规则逐渐浮出水面。',
        ),
      ];

      final characters = service.inferCharacterProfilesFromSource(
        '林砚在港口遇见议长，林砚发现黑潮议会正在追捕自己。林砚必须继续隐藏。',
      );
      final organizations = service.inferOrganizationProfilesFromSource(
        '黑潮议会掌管港口秩序。黑潮议会的密使已经出现。',
      );
      final worldRules = service.inferWorldRuleSetsFromSource(
        '港口的权力来自契约与禁忌，任何航线都必须遵守议会规则。',
        chapterSummaries,
      );
      final relationships = service.inferRelationshipRecords(
        characters,
        chapterSummaries,
        organizations,
      );
      final foreshadows = service.inferForeshadowRecordsFromChapterSummaries(
        chapterSummaries,
      );
      final timelines = service.inferTimelineRecordsFromChapterSummaries(
        chapterSummaries,
      );

      expect(characters, isNotEmpty);
      expect(organizations, isNotEmpty);
      expect(worldRules, isNotEmpty);
      expect(relationships, isNotEmpty);
      expect(foreshadows, isNotEmpty);
      expect(timelines, hasLength(2));
    });
  });
}
