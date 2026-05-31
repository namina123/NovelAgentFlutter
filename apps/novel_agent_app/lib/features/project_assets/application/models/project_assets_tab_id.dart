class ProjectAssetsTabId {
  static const String styles = 'styles';
  static const String expressionConstraints = 'expression_constraints';
  static const String foreshadows = 'foreshadows';
  static const String timelines = 'timelines';
  static const String relationships = 'relationships';
  static const String graph = 'graph';

  static const List<String> values = <String>[
    styles,
    expressionConstraints,
    foreshadows,
    timelines,
    relationships,
    graph,
  ];

  static bool supportsCreation(String tabId) =>
      tabId == styles || tabId == foreshadows;
}
