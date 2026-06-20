import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_rag_analysis_summary.dart';

class ProjectRagAnalysisSummaryDecoder {
  const ProjectRagAnalysisSummaryDecoder();

  ProjectRagAnalysisSummary decode(RagCorpusPackage? corpusPackage) {
    if (corpusPackage == null) {
      return ProjectRagAnalysisSummary.empty();
    }
    final metadata = corpusPackage.metadata;
    final rawSummary = ValueReaders.mapValue(
      metadata['source_analysis_summary'],
    );
    if (rawSummary.isEmpty) {
      return ProjectRagAnalysisSummary.empty();
    }
    return ProjectRagAnalysisSummary(
      storyOutlineSummary: ValueReaders.stringValue(
        rawSummary['story_outline_summary'],
      ).trim(),
      premiseSummary: ValueReaders.stringValue(
        rawSummary['premise_summary'],
      ).trim(),
      styleSummary: ValueReaders.stringValue(
        rawSummary['style_summary'],
      ).trim(),
      chapterTitles: _mapStringList(
        rawSummary['chapter_summaries'],
        key: 'title',
      ),
      characterNames: _mapStringList(
        rawSummary['character_clues'],
        key: 'name',
      ),
      organizationNames: _mapStringList(
        rawSummary['organization_clues'],
        key: 'name',
      ),
      worldRuleTitles: _mapStringList(
        rawSummary['world_rule_clues'],
        key: 'title',
      ),
      relationshipPairs: _mapStringList(
        rawSummary['relationship_clues'],
        key: 'pair',
      ),
      timelineLabels: _mapStringList(
        rawSummary['timeline_clues'],
        key: 'label',
      ),
      foreshadowTitles: _mapStringList(
        rawSummary['foreshadow_clues'],
        key: 'title',
      ),
    );
  }

  List<String> _mapStringList(Object? rawValue, {required String key}) {
    return ValueReaders.mapList(rawValue)
        .map(ValueReaders.mapValue)
        .map((entry) => ValueReaders.stringValue(entry[key]).trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
}
