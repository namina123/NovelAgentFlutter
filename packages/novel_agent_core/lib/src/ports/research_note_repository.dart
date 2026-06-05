import '../information/research_note.dart';
import '../project/project_descriptor.dart';

abstract class ResearchNoteRepository {
  Future<void> appendResearchNote(ProjectDescriptor project, ResearchNote note);

  Future<ResearchNote?> readResearchNote(
    ProjectDescriptor project, {
    required String researchId,
  });

  Future<List<ResearchNote>> listResearchNotes(
    ProjectDescriptor project, {
    String? sourceKind,
  });

  Future<void> updateResearchNote(ProjectDescriptor project, ResearchNote note);
}
