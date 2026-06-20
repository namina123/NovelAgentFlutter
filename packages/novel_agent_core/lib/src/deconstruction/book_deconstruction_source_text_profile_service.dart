import '../assets/character_profile.dart';
import '../assets/foreshadow_record.dart';
import '../assets/organization_profile.dart';
import '../assets/relationship_record.dart';
import '../assets/style_profile.dart';
import '../assets/timeline_record.dart';
import '../assets/world_rule_set.dart';
import '../source_analysis/source_analysis_chapter_summary.dart';
import '../source_analysis/source_analysis_narrative_asset_inference_service.dart';

class BookDeconstructionSourceTextProfileService {
  const BookDeconstructionSourceTextProfileService({
    SourceAnalysisNarrativeAssetInferenceService inferenceService =
        const SourceAnalysisNarrativeAssetInferenceService(),
  }) : _inferenceService = inferenceService;

  final SourceAnalysisNarrativeAssetInferenceService _inferenceService;

  List<StyleProfile> styleProfilesOf(String styleSummary) =>
      _inferenceService.styleProfilesOf(styleSummary);

  List<WorldRuleSet> worldRuleSetsOf(String worldRulesText) =>
      _inferenceService.worldRuleSetsOf(worldRulesText);

  List<CharacterProfile> characterProfilesOf(String characterLinesText) =>
      _inferenceService.characterProfilesOf(characterLinesText);

  List<OrganizationProfile> organizationProfilesOf(
    String organizationLinesText,
  ) => _inferenceService.organizationProfilesOf(organizationLinesText);

  List<CharacterProfile> inferCharacterProfilesFromSource(
    String sourceContent, {
    int maxCount = 24,
  }) => _inferenceService.inferCharacterProfilesFromSource(
    sourceContent,
    maxCount: maxCount,
  );

  List<OrganizationProfile> inferOrganizationProfilesFromSource(
    String sourceContent, {
    int maxCount = 16,
  }) => _inferenceService.inferOrganizationProfilesFromSource(
    sourceContent,
    maxCount: maxCount,
  );

  List<WorldRuleSet> inferWorldRuleSetsFromSource(
    String sourceContent,
    List<BookDeconstructionChapterSummary> chapterSummaries,
  ) => _inferenceService.inferWorldRuleSetsFromSource(
    sourceContent,
    _mapChapterSummaries(chapterSummaries),
  );

  List<TimelineRecord> inferTimelineRecordsFromChapters(
    List<BookDeconstructionChapterSummary> chapterSummaries,
  ) => _inferenceService.inferTimelineRecordsFromChapterSummaries(
    _mapChapterSummaries(chapterSummaries),
  );

  List<ForeshadowRecord> inferForeshadowRecordsFromChapters(
    List<BookDeconstructionChapterSummary> chapterSummaries,
  ) => _inferenceService.inferForeshadowRecordsFromChapterSummaries(
    _mapChapterSummaries(chapterSummaries),
  );

  List<RelationshipRecord> inferRelationshipRecords(
    List<CharacterProfile> characters,
    List<BookDeconstructionChapterSummary> chapterSummaries,
    List<OrganizationProfile> organizations,
  ) => _inferenceService.inferRelationshipRecords(
    characters,
    _mapChapterSummaries(chapterSummaries),
    organizations,
  );

  List<SourceAnalysisChapterSummary> _mapChapterSummaries(
    List<BookDeconstructionChapterSummary> chapterSummaries,
  ) {
    return chapterSummaries
        .map(
          (item) => SourceAnalysisChapterSummary(
            sequence: item.sequence,
            title: item.title,
            summary: item.summary,
          ),
        )
        .toList(growable: false);
  }
}

class BookDeconstructionChapterSummary {
  const BookDeconstructionChapterSummary({
    required this.sequence,
    required this.title,
    required this.summary,
  });

  final int sequence;
  final String title;
  final String summary;
}
