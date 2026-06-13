abstract final class InformationCollectionModes {
  static const String unknown = 'unknown';
  static const String network = 'network';
  static const String import = 'import';
  static const String hybrid = 'hybrid';
}

abstract final class InformationDomains {
  static const String general = 'general';
  static const String objective = 'objective';
  static const String history = 'history';
  static const String science = 'science';
  static const String technology = 'technology';
  static const String legal = 'legal';
  static const String medical = 'medical';
  static const String culture = 'culture';
  static const String sourceWork = 'source_work';
  static const String worldbuilding = 'worldbuilding';
  static const String creativeDesign = 'creative_design';
}

abstract final class InformationNetworkRegionHints {
  static const String auto = 'auto';
  static const String mainlandChinaPossible = 'mainland_china_possible';
  static const String global = 'global';
}

abstract final class InformationSourceRigorLevels {
  static const String unknown = 'unknown';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String authoritative = 'authoritative';
}
