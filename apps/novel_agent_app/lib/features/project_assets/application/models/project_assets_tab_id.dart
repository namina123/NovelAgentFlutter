class ProjectAssetsTabId {
  static const String referenceExtraction = 'reference_extraction';
  static const String styles = 'styles';
  static const String expressionConstraints = 'expression_constraints';
  static const String ragExtraction = 'rag_extraction';
  static const String foreshadows = 'foreshadows';
  static const String timelines = 'timelines';
  static const String relationships = 'relationships';
  static const String graph = 'graph';

  static const List<String> values = <String>[
    referenceExtraction,
    styles,
    expressionConstraints,
    ragExtraction,
    foreshadows,
    timelines,
    relationships,
    graph,
  ];

  static bool supportsCreation(String tabId) =>
      tabId == styles || tabId == foreshadows;
}
