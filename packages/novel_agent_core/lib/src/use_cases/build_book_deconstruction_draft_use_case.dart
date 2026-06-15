import '../deconstruction/book_deconstruction_application_plan_builder_service.dart';
import '../deconstruction/book_deconstruction_continuation_direction.dart';
import '../deconstruction/book_deconstruction_draft_build_result.dart';
import '../deconstruction/book_deconstruction_extraction_result.dart';
import '../deconstruction/book_deconstruction_followup_menu_builder_service.dart';
import '../deconstruction/book_deconstruction_input.dart';
import '../deconstruction/book_deconstruction_narrative_bridge_service.dart';
import '../deconstruction/book_deconstruction_source_document.dart';
import '../deconstruction/book_deconstruction_source_text_metadata_service.dart';
import '../deconstruction/book_deconstruction_source_text_outline_service.dart';
import '../deconstruction/book_deconstruction_source_text_profile_service.dart';
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
           const BookDeconstructionSourceTextOutlineService(),
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
    required String operatorNotes,
    required String styleSummary,
    required String worldRulesText,
    required String characterLinesText,
    required String organizationLinesText,
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
  }) {
    // 中文注释: 这个 use case 是拆书预演的正式编排入口，负责把输入、抽取、计划、叙事桥和后续菜单串成单一结果。
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
    final storyOutlineSummary = _sourceTextOutlineService.storyOutlineSummaryOf(
      cleanContent,
      chapterOutlines,
    );
    final premises = _sourceTextOutlineService.buildPremises(
      content: cleanContent,
      sourceAbsolutePath: sourceAbsolutePath,
      storyOutlineSummary: storyOutlineSummary,
    );
    final extractionResult = BookDeconstructionExtractionResult(
      extractionId: 'extract_${DateTime.now().microsecondsSinceEpoch}',
      sourceTitle: resolvedTitle,
      premises: premises,
      storyOutlineSummary: storyOutlineSummary,
      chapterOutlines: chapterOutlines,
      styleProfiles: _sourceTextProfileService.styleProfilesOf(styleSummary),
      worldRuleSets: _sourceTextProfileService.worldRuleSetsOf(worldRulesText),
      characterProfiles: _sourceTextProfileService.characterProfilesOf(
        characterLinesText,
      ),
      organizationProfiles: _sourceTextProfileService.organizationProfilesOf(
        organizationLinesText,
      ),
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
    final narrativeArtifacts = _narrativeBridgeService.build(
      input: input,
      extractionResult: extractionResult,
    );
    return BookDeconstructionDraftBuildResult(
      input: input,
      extractionResult: extractionResult,
      applicationPlan: applicationPlan,
      followupMenu: followupMenu,
      narrativeArtifacts: narrativeArtifacts,
    );
  }
}
