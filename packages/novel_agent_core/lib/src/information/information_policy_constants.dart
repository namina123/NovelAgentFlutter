abstract final class InformationSourceAuthorities {
  static const String userDeclared = 'user_declared';
  static const String sourceDocument = 'source_document';
  static const String deconstructionExtracted = 'deconstruction_extracted';
  static const String externalResearched = 'external_researched';
  static const String aiInferred = 'ai_inferred';
  static const String analysisInterpreted = 'analysis_interpreted';
}

abstract final class InformationRoleAuthorities {
  static const String writer = 'writer';
  static const String reviewer = 'reviewer';
  static const String researcher = 'researcher';
  static const String deconstructor = 'deconstructor';
  static const String explainer = 'explainer';
  static const String architect = 'architect';
  static const String user = 'user';
  static const String system = 'system';
}

abstract final class InformationResearchDepths {
  static const String none = 'none';
  static const String quick = 'quick';
  static const String standard = 'standard';
  static const String deep = 'deep';
}

abstract final class InformationActivationPriorities {
  static const String required = 'required';
  static const String pinned = 'pinned';
  static const String normal = 'normal';
  static const String reference = 'reference';
  static const String background = 'background';
}

abstract final class InformationUsageModes {
  static const String normal = 'normal';
  static const String referenceOnly = 'reference_only';
  static const String readOnly = 'read_only';
  static const String restricted = 'restricted';
}

abstract final class InformationCitationRiskLevels {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String highRisk = 'high_risk';
  static const String blocked = 'blocked';
}
