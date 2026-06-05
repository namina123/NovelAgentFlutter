class ChildFailureDispositions {
  static const String retryChild = 'retry_child';
  static const String skipChild = 'skip_child';
  static const String fallbackSingleMain = 'fallback_single_main';
  static const String requireUser = 'require_user';

  static const Set<String> knownValues = <String>{
    retryChild,
    skipChild,
    fallbackSingleMain,
    requireUser,
  };

  static bool isKnown(String value) => knownValues.contains(value.trim());

  static bool blocksProgress(String value) {
    final clean = value.trim();
    return clean == retryChild || clean == requireUser;
  }
}
