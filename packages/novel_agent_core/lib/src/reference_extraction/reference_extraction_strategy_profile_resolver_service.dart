import 'reference_extraction_execution_profile.dart';
import 'reference_extraction_strategy_profile_catalog_service.dart';
import 'reference_extraction_strategy_profile.dart';
import '../output/output_contract_models.dart';

class ReferenceExtractionStrategyProfileResolverService {
  const ReferenceExtractionStrategyProfileResolverService({
    ReferenceExtractionStrategyProfileCatalogService? catalogService,
  }) : _catalogService =
           catalogService ??
           const ReferenceExtractionStrategyProfileCatalogService();

  final ReferenceExtractionStrategyProfileCatalogService _catalogService;

  ReferenceExtractionStrategyProfile resolve({
    required ReferenceExtractionExecutionProfile executionProfile,
    String overrideProfileId = '',
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    final cleanOverrideId = overrideProfileId.trim();
    if (cleanOverrideId.isEmpty) {
      return _inheritSharedContracts(
        executionProfile.strategyProfile,
        baseProfile: executionProfile.strategyProfile,
      );
    }
    final resolved =
        _catalogService.byId(
          cleanOverrideId,
          additionalProfiles: additionalProfiles,
        ) ??
        executionProfile.strategyProfile;
    return _inheritSharedContracts(
      resolved,
      baseProfile: executionProfile.strategyProfile,
    );
  }

  ReferenceExtractionStrategyProfile _inheritSharedContracts(
    ReferenceExtractionStrategyProfile profile, {
    required ReferenceExtractionStrategyProfile baseProfile,
  }) {
    final outputCoverageContract =
        profile.outputCoverageContract.dimensions.isEmpty &&
            profile.outputCoverageContract.contractId.trim().isEmpty
        ? baseProfile.outputCoverageContract
        : profile.outputCoverageContract;
    final outputBudgetPolicy =
        _looksLikeDefaultOutputBudgetPolicy(profile.outputBudgetPolicy)
        ? baseProfile.outputBudgetPolicy
        : profile.outputBudgetPolicy;
    return profile.copyWith(
      outputCoverageContract: outputCoverageContract,
      outputBudgetPolicy: outputBudgetPolicy,
    );
  }

  bool _looksLikeDefaultOutputBudgetPolicy(OutputBudgetPolicy policy) {
    return policy.targetOutputDensity == OutputDensityModes.balanced &&
        policy.minOutputSlots == 4 &&
        policy.maxOutputSlots == 6 &&
        policy.maxSummaryCharsPerItem == 180 &&
        policy.mustReportOmissions &&
        policy.continuationAllowed &&
        policy.preferredOutputLanguage == 'zh-CN' &&
        policy.compressionFallbackMode ==
            OutputCompressionFallbackModes.preserveCoverage &&
        policy.metadata.isEmpty;
  }
}
