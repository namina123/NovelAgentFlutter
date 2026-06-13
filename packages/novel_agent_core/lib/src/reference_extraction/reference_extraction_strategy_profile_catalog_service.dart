import 'reference_extraction_strategy_profile.dart';

class ReferenceExtractionStrategyProfileCatalogService {
  const ReferenceExtractionStrategyProfileCatalogService();

  List<ReferenceExtractionStrategyProfile> builtinProfiles() {
    return const <ReferenceExtractionStrategyProfile>[
      ReferenceExtractionStrategyProfiles.standard,
      ReferenceExtractionStrategyProfiles.bulkLongContext,
      ReferenceExtractionStrategyProfiles.factFocused,
      ReferenceExtractionStrategyProfiles.exploratory,
    ];
  }

  List<ReferenceExtractionStrategyProfile> allProfiles({
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    final merged = <String, ReferenceExtractionStrategyProfile>{};
    for (final profile in builtinProfiles()) {
      merged[profile.profileId] = profile;
    }
    for (final profile in additionalProfiles) {
      final cleanId = profile.profileId.trim();
      if (cleanId.isEmpty) {
        continue;
      }
      merged[cleanId] = profile;
    }
    return merged.values.toList(growable: false);
  }

  ReferenceExtractionStrategyProfile? byId(
    String profileId, {
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    final cleanId = profileId.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    for (final profile in allProfiles(additionalProfiles: additionalProfiles)) {
      if (profile.profileId == cleanId) {
        return profile;
      }
    }
    return null;
  }

  bool isBuiltinProfileId(String profileId) {
    final cleanId = profileId.trim();
    if (cleanId.isEmpty) {
      return false;
    }
    return builtinProfiles().any((profile) => profile.profileId == cleanId);
  }

  String normalizeProfileId(
    String profileId, {
    List<ReferenceExtractionStrategyProfile> additionalProfiles =
        const <ReferenceExtractionStrategyProfile>[],
  }) {
    final matched = byId(profileId, additionalProfiles: additionalProfiles);
    return matched?.profileId ??
        ReferenceExtractionBuiltinStrategyProfileIds.standard;
  }
}
