import 'design_element_card.dart';
import 'project_knowledge_card.dart';
import 'reference_work_record.dart';
import 'research_note.dart';

class InformationProjectionDraftBundle {
  const InformationProjectionDraftBundle({
    required this.projectionId,
    required this.relativePath,
    this.projectionOnly = true,
    this.knowledgeCardDrafts = const <ProjectKnowledgeCard>[],
    this.designElementDrafts = const <DesignElementCard>[],
    this.researchNoteDrafts = const <ResearchNote>[],
    this.referenceWorkDrafts = const <ReferenceWorkRecord>[],
    this.warnings = const <String>[],
  });

  final String projectionId;
  final String relativePath;
  final bool projectionOnly;
  final List<ProjectKnowledgeCard> knowledgeCardDrafts;
  final List<DesignElementCard> designElementDrafts;
  final List<ResearchNote> researchNoteDrafts;
  final List<ReferenceWorkRecord> referenceWorkDrafts;
  final List<String> warnings;

  bool get isEmpty =>
      knowledgeCardDrafts.isEmpty &&
      designElementDrafts.isEmpty &&
      researchNoteDrafts.isEmpty &&
      referenceWorkDrafts.isEmpty;
}
