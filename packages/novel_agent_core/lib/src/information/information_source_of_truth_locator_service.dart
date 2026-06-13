abstract final class InformationSourceOfTruthCollections {
  static const String knowledgeCards = 'knowledge_cards';
  static const String designElements = 'design_elements';
  static const String researchNotes = 'research_notes';
  static const String referenceWorks = 'reference_works';
}

class InformationSourceOfTruthLocatorService {
  const InformationSourceOfTruthLocatorService();

  String collectionLocator(String collectionName) {
    return 'project-information://${collectionName.trim()}';
  }

  String entryLocator(String collectionName, String entryId) {
    final cleanCollectionName = collectionName.trim();
    final cleanEntryId = entryId.trim();
    if (cleanEntryId.isEmpty) {
      return collectionLocator(cleanCollectionName);
    }
    return '${collectionLocator(cleanCollectionName)}/$cleanEntryId';
  }

  String knowledgeCardsCollectionLocator() {
    return collectionLocator(
      InformationSourceOfTruthCollections.knowledgeCards,
    );
  }

  String designElementsCollectionLocator() {
    return collectionLocator(
      InformationSourceOfTruthCollections.designElements,
    );
  }

  String researchNotesCollectionLocator() {
    return collectionLocator(InformationSourceOfTruthCollections.researchNotes);
  }

  String referenceWorksCollectionLocator() {
    return collectionLocator(
      InformationSourceOfTruthCollections.referenceWorks,
    );
  }
}
