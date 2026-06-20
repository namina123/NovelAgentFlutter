import 'package:novel_agent_core/novel_agent_core.dart';

class RagSourceAnalysisSummaryBuilder {
  const RagSourceAnalysisSummaryBuilder({
    SourceAnalysisOutlineService outlineService =
        const SourceAnalysisOutlineService(),
    SourceAnalysisNarrativeAssetInferenceService narrativeInferenceService =
        const SourceAnalysisNarrativeAssetInferenceService(),
    SourceAnalysisStyleSignalService styleSignalService =
        const SourceAnalysisStyleSignalService(),
  }) : _outlineService = outlineService,
       _narrativeInferenceService = narrativeInferenceService,
       _styleSignalService = styleSignalService;

  final SourceAnalysisOutlineService _outlineService;
  final SourceAnalysisNarrativeAssetInferenceService _narrativeInferenceService;
  final SourceAnalysisStyleSignalService _styleSignalService;

  JsonMap build({
    required String normalizedText,
    required List<ReferenceSourceDocumentSection> sections,
    required String targetLanguage,
  }) {
    final outline = _outlineService.analyze(normalizedText);
    final styleMetrics = _styleSignalService.analyze(
      normalizedText: normalizedText,
      sections: sections,
    );
    final styleSummary = _styleSignalService.localizedSummary(
      styleMetrics,
      targetLanguage: targetLanguage,
    );
    final chapterSummaries = outline.chapterSummaries;
    final characters = _narrativeInferenceService
        .inferCharacterProfilesFromSource(normalizedText, maxCount: 12);
    final organizations = _narrativeInferenceService
        .inferOrganizationProfilesFromSource(normalizedText, maxCount: 8);
    final worldRules = _narrativeInferenceService.inferWorldRuleSetsFromSource(
      normalizedText,
      chapterSummaries,
    );
    final relationships = _narrativeInferenceService.inferRelationshipRecords(
      characters,
      chapterSummaries,
      organizations,
    );
    final timelines = _narrativeInferenceService
        .inferTimelineRecordsFromChapterSummaries(chapterSummaries);
    final foreshadows = _narrativeInferenceService
        .inferForeshadowRecordsFromChapterSummaries(chapterSummaries);
    return <String, Object?>{
      'story_outline_summary': outline.storyOutlineSummary,
      'premise_summary': outline.premiseSummary,
      'style_summary': styleSummary,
      'style_metrics': <String, Object?>{
        'section_count': styleMetrics.sectionCount,
        'paragraph_count': styleMetrics.paragraphCount,
        'dialogue_quote_count': styleMetrics.dialogueQuoteCount,
        'average_section_length_chars': styleMetrics.averageSectionLengthChars,
      },
      'chapter_summaries': chapterSummaries
          .take(8)
          .map(
            (chapter) => <String, Object?>{
              'sequence': chapter.sequence,
              'title': chapter.title,
              'summary': chapter.summary,
              'keywords': chapter.keywords,
            },
          )
          .toList(growable: false),
      'character_clues': characters
          .take(8)
          .map(
            (item) => <String, Object?>{
              'name': item.displayName,
              'summary': item.summary,
              'mention_count': item.metadata['mention_count'],
            },
          )
          .toList(growable: false),
      'organization_clues': organizations
          .take(6)
          .map(
            (item) => <String, Object?>{
              'name': item.displayName,
              'summary': item.summary,
              'mention_count': item.metadata['mention_count'],
            },
          )
          .toList(growable: false),
      'world_rule_clues': worldRules
          .take(4)
          .map(
            (item) => <String, Object?>{
              'title': item.displayName,
              'summary': item.summary,
              'rules': item.rules.take(6).toList(growable: false),
            },
          )
          .toList(growable: false),
      'relationship_clues': relationships
          .take(6)
          .map(
            (item) => <String, Object?>{
              'pair': item.displayName,
              'summary': item.summary,
              'relationship_type': item.relationshipType,
            },
          )
          .toList(growable: false),
      'timeline_clues': timelines
          .take(8)
          .map(
            (item) => <String, Object?>{
              'label': item.displayName,
              'summary': item.summary,
              'phase_label': item.phaseLabel,
              'sequence': item.sequence,
            },
          )
          .toList(growable: false),
      'foreshadow_clues': foreshadows
          .take(6)
          .map(
            (item) => <String, Object?>{
              'title': item.title,
              'summary': item.summary,
              'status': item.status,
            },
          )
          .toList(growable: false),
    };
  }
}
