import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionStrategyProfileCatalogService', () {
    const service = ReferenceExtractionStrategyProfileCatalogService();

    test('returns builtin profiles and allows additional override by id', () {
      final custom = const ReferenceExtractionStrategyProfile(
        profileId: 'reference_extraction.custom_dense',
        proposalPolicy: ReferenceExtractionProposalPolicy(
          minProposalCount: 6,
          maxProposalCount: 9,
        ),
      );

      final allProfiles = service.allProfiles(
        additionalProfiles: <ReferenceExtractionStrategyProfile>[custom],
      );

      expect(
        allProfiles.map((item) => item.profileId),
        containsAll(<String>[
          ReferenceExtractionBuiltinStrategyProfileIds.standard,
          ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
          'reference_extraction.custom_dense',
        ]),
      );
      final resolved = service.byId(
        'reference_extraction.custom_dense',
        additionalProfiles: <ReferenceExtractionStrategyProfile>[custom],
      );
      expect(resolved, isNotNull);
      expect(resolved!.proposalPolicy.maxProposalCount, 9);
    });
  });
}
