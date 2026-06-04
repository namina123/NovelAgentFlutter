abstract final class ContextActivationReasonCodes {
  static const String keyword = 'keyword';
  static const String ref = 'ref';
  static const String claim = 'claim';
  static const String profilePolicy = 'profile_policy';
  static const String taskType = 'task_type';
  static const String manualPin = 'manual_pin';
  static const String semanticRetrieval = 'semantic_retrieval';

  static const List<String> knownValues = <String>[
    keyword,
    ref,
    claim,
    profilePolicy,
    taskType,
    manualPin,
    semanticRetrieval,
  ];
}
