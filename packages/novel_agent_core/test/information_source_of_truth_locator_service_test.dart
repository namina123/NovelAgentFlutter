import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('InformationSourceOfTruthLocatorService', () {
    const service = InformationSourceOfTruthLocatorService();

    test('builds stable collection locators for project information truth', () {
      expect(
        service.knowledgeCardsCollectionLocator(),
        'project-information://knowledge_cards',
      );
      expect(
        service.designElementsCollectionLocator(),
        'project-information://design_elements',
      );
      expect(
        service.researchNotesCollectionLocator(),
        'project-information://research_notes',
      );
      expect(
        service.referenceWorksCollectionLocator(),
        'project-information://reference_works',
      );
    });

    test('builds entry locators without inventing a second locator format', () {
      expect(
        service.entryLocator(
          InformationSourceOfTruthCollections.knowledgeCards,
          'knowledge-1',
        ),
        'project-information://knowledge_cards/knowledge-1',
      );
      expect(
        service.entryLocator(
          InformationSourceOfTruthCollections.referenceWorks,
          '',
        ),
        'project-information://reference_works',
      );
    });
  });
}
