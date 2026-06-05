import 'design_element_card.dart';
import 'project_knowledge_card.dart';
import 'reference_work_record.dart';
import 'research_note.dart';

class InformationProjectionSource {
  const InformationProjectionSource({
    this.knowledgeCards = const <ProjectKnowledgeCard>[],
    this.designElements = const <DesignElementCard>[],
    this.researchNotes = const <ResearchNote>[],
    this.referenceWorks = const <ReferenceWorkRecord>[],
  });

  final List<ProjectKnowledgeCard> knowledgeCards;
  final List<DesignElementCard> designElements;
  final List<ResearchNote> researchNotes;
  final List<ReferenceWorkRecord> referenceWorks;
}
