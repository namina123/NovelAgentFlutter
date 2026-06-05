import '../information/project_knowledge_card.dart';
import '../project/project_descriptor.dart';

abstract class KnowledgeCardRepository {
  Future<void> appendKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  );

  Future<ProjectKnowledgeCard?> readKnowledgeCard(
    ProjectDescriptor project, {
    required String cardId,
  });

  Future<List<ProjectKnowledgeCard>> listKnowledgeCards(
    ProjectDescriptor project, {
    String? cardNamespace,
  });

  Future<void> updateKnowledgeCard(
    ProjectDescriptor project,
    ProjectKnowledgeCard card,
  );
}
