import '../assets/character_profile.dart';
import '../assets/foreshadow_record.dart';
import '../assets/organization_profile.dart';
import '../assets/relationship_record.dart';
import '../assets/style_profile.dart';
import '../assets/timeline_record.dart';
import '../assets/world_rule_set.dart';
import '../deconstruction/book_deconstruction_continuation_direction.dart';
import '../deconstruction/book_deconstruction_draft_build_result.dart';
import '../deconstruction/book_deconstruction_extraction_result.dart';
import '../deconstruction/book_deconstruction_followup_menu_builder_service.dart';
import '../deconstruction/book_deconstruction_input.dart';
import '../deconstruction/book_deconstruction_narrative_artifact_bundle.dart';
import '../deconstruction/book_deconstruction_narrative_bridge_service.dart';
import '../deconstruction/book_deconstruction_source_document.dart';
import '../deconstruction/book_deconstruction_source_text_metadata_service.dart';
import '../deconstruction/book_deconstruction_source_text_outline_service.dart';
import '../deconstruction/book_deconstruction_source_text_profile_service.dart';
import '../inspiration/inspiration_premise.dart';
import 'build_book_deconstruction_application_plan_use_case.dart';

class BuildBookDeconstructionDraftUseCase {
  BuildBookDeconstructionDraftUseCase({
    BookDeconstructionSourceTextMetadataService? sourceTextMetadataService,
    BookDeconstructionSourceTextOutlineService? sourceTextOutlineService,
    BookDeconstructionSourceTextProfileService? sourceTextProfileService,
    BuildBookDeconstructionApplicationPlanUseCase? buildApplicationPlanUseCase,
    BookDeconstructionFollowupMenuBuilderService? followupMenuBuilderService,
    BookDeconstructionNarrativeBridgeService? narrativeBridgeService,
  }) : _sourceTextMetadataService =
           sourceTextMetadataService ??
           const BookDeconstructionSourceTextMetadataService(),
       _sourceTextOutlineService =
           sourceTextOutlineService ??
           BookDeconstructionSourceTextOutlineService(),
       _sourceTextProfileService =
           sourceTextProfileService ??
           const BookDeconstructionSourceTextProfileService(),
       _buildApplicationPlanUseCase =
           buildApplicationPlanUseCase ??
           BuildBookDeconstructionApplicationPlanUseCase(),
       _followupMenuBuilderService =
           followupMenuBuilderService ??
           const BookDeconstructionFollowupMenuBuilderService(),
       _narrativeBridgeService =
           narrativeBridgeService ??
           const BookDeconstructionNarrativeBridgeService();

  final BookDeconstructionSourceTextMetadataService _sourceTextMetadataService;
  final BookDeconstructionSourceTextOutlineService _sourceTextOutlineService;
  final BookDeconstructionSourceTextProfileService _sourceTextProfileService;
  final BuildBookDeconstructionApplicationPlanUseCase
  _buildApplicationPlanUseCase;
  final BookDeconstructionFollowupMenuBuilderService
  _followupMenuBuilderService;
  final BookDeconstructionNarrativeBridgeService _narrativeBridgeService;

  BookDeconstructionDraftBuildResult execute({
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    String operatorNotes = '',
    String styleSummary = '',
    String worldRulesText = '',
    String characterLinesText = '',
    String organizationLinesText = '',
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    bool extractKnowledge = true,
  }) {
    // 中文注释: 这个 use case 是拆书预演的正式编排入口，负责把输入、抽取、计划、叙事桥和后续菜单串成单一结果。
    // extractKnowledge=false = 纯拆书（只分章 + 章节骨架），不做任何知识抽取——拆书就是拆书。
    // extractKnowledge=true（默认，向后兼容）= 在分章之上做完整启发式知识抽取；这是可选的"提取知识"阶段。
    final cleanContent = sourceContent.trim();
    if (cleanContent.isEmpty) {
      throw StateError('请先导入或粘贴拆书源文稿。');
    }
    final resolvedTitle = _sourceTextMetadataService.resolveSourceTitle(
      sourceTitle: sourceTitle,
      sourceAbsolutePath: sourceAbsolutePath,
      sourceContent: cleanContent,
    );
    final sourceDocument = BookDeconstructionSourceDocument(
      id: 'source_primary',
      title: resolvedTitle,
      content: cleanContent,
      mediaType: _sourceTextMetadataService.mediaTypeOf(sourceAbsolutePath),
      relativePathHint: sourceAbsolutePath.trim(),
      sequence: 1,
    );
    final chapterOutlines = _sourceTextOutlineService.chapterOutlinesOf(
      cleanContent,
    );
    final chapterSummaries = chapterOutlines
        .map(
          (item) => BookDeconstructionChapterSummary(
            sequence: item.sequence,
            title: item.title,
            summary: item.summary,
          ),
        )
        .toList(growable: false);
    final List<InspirationPremise> premises;
    final String storyOutlineSummary;
    final List<StyleProfile> sourceStyleProfiles;
    final List<WorldRuleSet> sourceWorldRuleSets;
    final List<CharacterProfile> sourceCharacterProfiles;
    final List<OrganizationProfile> sourceOrganizationProfiles;
    final List<TimelineRecord> timelineRecords;
    final List<ForeshadowRecord> foreshadowRecords;
    final List<RelationshipRecord> relationshipRecords;
    if (extractKnowledge) {
      // 中文注释: 提取知识（可选阶段）：在分章之上做故事总纲/前提/风格/世界/角色/组织/时间线/伏笔/关系抽取。
      storyOutlineSummary = _sourceTextOutlineService.storyOutlineSummaryOf(
        cleanContent,
        chapterOutlines,
      );
      premises = _sourceTextOutlineService.buildPremises(
        content: cleanContent,
        sourceAbsolutePath: sourceAbsolutePath,
        storyOutlineSummary: storyOutlineSummary,
      );
      final inferredStyleProfiles = _sourceTextProfileService.styleProfilesOf(
        styleSummary,
      );
      final inferredWorldRuleSets = _sourceTextProfileService.worldRuleSetsOf(
        worldRulesText,
      );
      final inferredCharacterProfiles =
          _sourceTextProfileService.characterProfilesOf(characterLinesText);
      final inferredOrganizationProfiles =
          _sourceTextProfileService.organizationProfilesOf(
            organizationLinesText,
          );
      sourceCharacterProfiles = inferredCharacterProfiles.isEmpty
          ? _sourceTextProfileService.inferCharacterProfilesFromSource(cleanContent)
          : inferredCharacterProfiles;
      sourceOrganizationProfiles = inferredOrganizationProfiles.isEmpty
          ? _sourceTextProfileService.inferOrganizationProfilesFromSource(cleanContent)
          : inferredOrganizationProfiles;
      sourceWorldRuleSets = inferredWorldRuleSets.isEmpty
          ? _sourceTextProfileService.inferWorldRuleSetsFromSource(
              cleanContent,
              chapterSummaries,
            )
          : inferredWorldRuleSets;
      sourceStyleProfiles = inferredStyleProfiles.isEmpty &&
              storyOutlineSummary.trim().isNotEmpty
          ? <StyleProfile>[
              StyleProfile(
                id: 'deconstruction_style_inferred',
                displayName: '原文推断叙事风格',
                summary: _sourceTextOutlineService.premiseSummaryOf(
                  cleanContent,
                  storyOutlineSummary,
                ),
                metadata: const <String, Object?>{'inferred_from_source': true},
              ),
            ]
          : inferredStyleProfiles;
      timelineRecords = _sourceTextProfileService.inferTimelineRecordsFromChapters(
        chapterSummaries,
      );
      foreshadowRecords =
          _sourceTextProfileService.inferForeshadowRecordsFromChapters(
            chapterSummaries,
          );
      relationshipRecords = _sourceTextProfileService.inferRelationshipRecords(
        sourceCharacterProfiles,
        chapterSummaries,
        sourceOrganizationProfiles,
      );
    } else {
      // 中文注释: 纯拆书（默认走这条的是 GUI 的"拆书"按钮）：只分章 + 章节骨架，
      // 不派生故事总纲/前提/角色/世界/时间线/伏笔/关系等任何知识——拆书不涉及其他。
      storyOutlineSummary = '';
      premises = const <InspirationPremise>[];
      sourceStyleProfiles = const <StyleProfile>[];
      sourceWorldRuleSets = const <WorldRuleSet>[];
      sourceCharacterProfiles = const <CharacterProfile>[];
      sourceOrganizationProfiles = const <OrganizationProfile>[];
      timelineRecords = const <TimelineRecord>[];
      foreshadowRecords = const <ForeshadowRecord>[];
      relationshipRecords = const <RelationshipRecord>[];
    }
    final extractionResult = BookDeconstructionExtractionResult(
      extractionId: 'extract_${DateTime.now().microsecondsSinceEpoch}',
      sourceTitle: resolvedTitle,
      premises: premises,
      storyOutlineSummary: storyOutlineSummary,
      chapterOutlines: chapterOutlines,
      styleProfiles: sourceStyleProfiles,
      worldRuleSets: sourceWorldRuleSets,
      characterProfiles: sourceCharacterProfiles,
      organizationProfiles: sourceOrganizationProfiles,
      timelineRecords: timelineRecords,
      foreshadowRecords: foreshadowRecords,
      relationshipRecords: relationshipRecords,
      notes: operatorNotes.trim(),
    );
    final input = BookDeconstructionInput(
      extractionId: extractionResult.extractionId,
      title: resolvedTitle,
      sourceDocuments: <BookDeconstructionSourceDocument>[sourceDocument],
      preferredContinuationDirection: preferredContinuationDirection,
      operatorNotes: operatorNotes.trim(),
      metadata: <String, Object?>{
        if (sourceAbsolutePath.trim().isNotEmpty)
          'source_absolute_path': sourceAbsolutePath.trim(),
      },
    );
    final applicationPlan = _buildApplicationPlanUseCase.execute(
      input: input,
      extractionResult: extractionResult,
    );
    final followupMenu = _followupMenuBuilderService.build(
      preferredDirection: preferredContinuationDirection,
    );
    // 中文注释: 纯拆书不跑叙事桥（那是分析输出，属于可选的知识提取阶段）；只有 extractKnowledge=true 才产出 claims/proposals/reviews。
    final narrativeArtifacts = extractKnowledge
        ? _narrativeBridgeService.build(
            input: input,
            extractionResult: extractionResult,
          )
        : BookDeconstructionNarrativeArtifactBundle();
    return BookDeconstructionDraftBuildResult(
      input: input,
      extractionResult: extractionResult,
      applicationPlan: applicationPlan,
      followupMenu: followupMenu,
      narrativeArtifacts: narrativeArtifacts,
    );
  }
}
