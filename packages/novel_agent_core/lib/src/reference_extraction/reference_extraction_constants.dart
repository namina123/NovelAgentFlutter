abstract final class ReferenceExtractionExecutionModes {
  static const String group = 'group';
  static const String singleAgentFallback = 'single_agent_fallback';
}

abstract final class ReferenceExtractionResolutionKinds {
  static const String taskFamilyOverride = 'task_family_override';
  static const String capableGroup = 'capable_group';
  static const String singleAgentFallback = 'single_agent_fallback';
}

abstract final class ReferenceExtractionPromptProfiles {
  static const String group = 'reference_extraction.group';
  static const String singleAgent = 'reference_extraction.single_agent';
}

abstract final class ReferenceExtractionToolPermissionProfiles {
  static const String standard = 'reference_extraction.standard';
}

abstract final class ReferenceExtractionWorkflowPhases {
  static const String seedExtraction = 'seed_extraction';
  static const String groupResolution = 'group_resolution';
  static const String batchPlanning = 'batch_planning';
  static const String batchExecution = 'batch_execution';
  static const String proposalGeneration = 'proposal_generation';
  static const String reviewGate = 'review_gate';
  static const String packageFinalize = 'package_finalize';
}

abstract final class ReferenceExtractionReviewDispositions {
  static const String accepted = 'accepted';
  static const String candidateOnly = 'candidate_only';
  static const String needsRework = 'needs_rework';
}
