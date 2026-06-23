class BookDeconstructionOperationKind {
  static const String idle = 'idle';
  static const String importingSource = 'importing_source';
  static const String splittingChapters = 'splitting_chapters';
  static const String analyzingAssets = 'analyzing_assets';
  static const String confirmingSelection = 'confirming_selection';
  static const String creatingDerivedProject = 'creating_derived_project';

  static String normalize(String value) {
    switch (value.trim()) {
      case importingSource:
      case splittingChapters:
      case analyzingAssets:
      case confirmingSelection:
      case creatingDerivedProject:
        return value.trim();
      default:
        return idle;
    }
  }
}
