enum RuntimeExposureTier { standard, advanced, diagnostic }

class RuntimeExposurePolicyService {
  const RuntimeExposurePolicyService();

  bool exposesInternalRuntimeTerms(RuntimeExposureTier tier) {
    return tier != RuntimeExposureTier.standard;
  }

  bool exposesStructuredEvidence(RuntimeExposureTier tier) {
    return tier != RuntimeExposureTier.standard;
  }

  bool exposesRawJson(RuntimeExposureTier tier) {
    return tier == RuntimeExposureTier.diagnostic;
  }

  bool exposesFileSystemSource(RuntimeExposureTier tier) {
    return tier == RuntimeExposureTier.diagnostic;
  }
}
