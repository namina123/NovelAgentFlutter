abstract final class ReferencePackageKinds {
  static const String referenceWorkPackage = 'reference_work_package';
  static const String domainEvidencePackage = 'domain_evidence_package';
  static const String styleTechniqueProfile = 'style_technique_profile';
  static const String processDependencyPackage = 'process_dependency_package';
  static const String projectDivergenceSnapshot = 'project_divergence_snapshot';
  static const String microReferenceShard = 'micro_reference_shard';
}

abstract final class ReferenceEntryKinds {
  static const String knowledgeFact = 'knowledge_fact';
  static const String designElement = 'design_element';
  static const String styleTechnique = 'style_technique';
  static const String processDependency = 'process_dependency';
  static const String divergenceSnapshot = 'divergence_snapshot';
  static const String microReferenceShard = 'micro_reference_shard';
  static const String researchNote = 'research_note';
  static const String referenceWorkBoundary = 'reference_work_boundary';
}

abstract final class ReferenceVisibilityModes {
  static const String hidden = 'hidden';
  static const String mountedOnly = 'mounted_only';
  static const String discoverable = 'discoverable';
}

abstract final class ReferenceAccessLevels {
  static const String none = 'none';
  static const String summaryOnly = 'summary_only';
  static const String readOnly = 'read_only';
  static const String projectable = 'projectable';
  static const String manager = 'manager';
}

abstract final class ReferenceAccessOperations {
  static const String discoverPackage = 'discover_package';
  static const String readPackageSummary = 'read_package_summary';
  static const String readEntry = 'read_entry';
  static const String projectEntry = 'project_entry';
  static const String promoteProjectInformation = 'promote_project_information';
}

abstract final class ReferenceAccessDispositions {
  static const String allowed = 'allowed';
  static const String denied = 'denied';
  static const String hidden = 'hidden';
  static const String confirmationRequired = 'confirmation_required';
}

abstract final class ReferenceProjectionStatuses {
  static const String applied = 'applied';
  static const String denied = 'denied';
  static const String missingAttachment = 'missing_attachment';
  static const String missingPackage = 'missing_package';
}

abstract final class ReferencePromotionStatuses {
  static const String promoted = 'promoted';
  static const String sourceMissing = 'source_missing';
  static const String invalidRequest = 'invalid_request';
}

abstract final class ProjectInformationArtifactKinds {
  static const String knowledgeCard = 'knowledge_card';
  static const String designElement = 'design_element';
  static const String researchNote = 'research_note';
  static const String referenceWork = 'reference_work';
}

abstract final class ReferenceBundleConstants {
  static const String bundleSchemaVersion = '1';
  static const String payloadDirectory = 'payload';
  static const String projectionsDirectory = 'projections';
  static const String attachmentsDirectory = 'attachments';
  static const String integrityDirectory = 'integrity';
  static const String manifestFileName = 'manifest.json';
  static const String packageFileName = 'package.json';
  static const String versionFileName = 'version.json';
  static const String entriesFileName = 'entries.json';
  static const String dependenciesFileName = 'dependencies.json';
  static const String promotionsFileName = 'promotions.json';
  static const String integrityFileName = 'checksums.json';
}
