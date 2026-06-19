class BookDeconstructionOperationKind {
  static const String idle = 'idle';
  static const String importingSource = 'importing_source';
  static const String buildingPreview = 'building_preview';
  static const String confirmingSelection = 'confirming_selection';
  static const String creatingDerivedProject = 'creating_derived_project';

  static String normalize(String value) {
    switch (value.trim()) {
      case importingSource:
      case buildingPreview:
      case confirmingSelection:
      case creatingDerivedProject:
        return value.trim();
      default:
        return idle;
    }
  }
}
