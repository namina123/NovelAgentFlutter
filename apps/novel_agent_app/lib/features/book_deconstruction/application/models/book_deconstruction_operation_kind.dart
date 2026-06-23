class BookDeconstructionOperationKind {
  static const String idle = 'idle';
  static const String importingSource = 'importing_source';
  static const String smartImportingSource = 'smart_importing_source';
  static const String buildingPreview = 'building_preview';
  static const String extractingKnowledge = 'extracting_knowledge';
  static const String confirmingSelection = 'confirming_selection';
  static const String creatingDerivedProject = 'creating_derived_project';

  static String normalize(String value) {
    switch (value.trim()) {
      case importingSource:
      case smartImportingSource:
      case buildingPreview:
      case extractingKnowledge:
      case confirmingSelection:
      case creatingDerivedProject:
        return value.trim();
      default:
        return idle;
    }
  }
}
