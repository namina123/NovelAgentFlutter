import '../assets/character_profile.dart';
import '../assets/foreshadow_record.dart';
import '../assets/organization_profile.dart';
import '../assets/relationship_record.dart';
import '../assets/style_profile.dart';
import '../assets/timeline_record.dart';
import '../assets/world_rule_set.dart';
import '../inspiration/inspiration_premise.dart';
import 'book_deconstruction_chapter_outline.dart';
import 'book_deconstruction_continuity_hints.dart';
import 'book_deconstruction_constants.dart';

class BookDeconstructionExtractionResult {
  const BookDeconstructionExtractionResult({
    required this.extractionId,
    required this.sourceTitle,
    this.projectStrategyId = BookDeconstructionConstants.projectStrategyId,
    this.modeId = BookDeconstructionConstants.modeAssetExtraction,
    this.premises = const <InspirationPremise>[],
    this.storyOutlineSummary = '',
    this.chapterOutlines = const <BookDeconstructionChapterOutline>[],
    this.styleProfiles = const <StyleProfile>[],
    this.worldRuleSets = const <WorldRuleSet>[],
    this.characterProfiles = const <CharacterProfile>[],
    this.organizationProfiles = const <OrganizationProfile>[],
    this.foreshadowRecords = const <ForeshadowRecord>[],
    this.timelineRecords = const <TimelineRecord>[],
    this.relationshipRecords = const <RelationshipRecord>[],
    this.continuityHints = const BookDeconstructionContinuityHints(),
    this.notes = '',
    this.metadata = const <String, Object?>{},
  });

  final String extractionId;
  final String sourceTitle;
  final String projectStrategyId;
  final String modeId;
  final List<InspirationPremise> premises;
  final String storyOutlineSummary;
  final List<BookDeconstructionChapterOutline> chapterOutlines;
  final List<StyleProfile> styleProfiles;
  final List<WorldRuleSet> worldRuleSets;
  final List<CharacterProfile> characterProfiles;
  final List<OrganizationProfile> organizationProfiles;
  final List<ForeshadowRecord> foreshadowRecords;
  final List<TimelineRecord> timelineRecords;
  final List<RelationshipRecord> relationshipRecords;
  final BookDeconstructionContinuityHints continuityHints;
  final String notes;
  final Map<String, Object?> metadata;
}
