import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceExtractionStrategyProfileResolverService', () {
    const service = ReferenceExtractionStrategyProfileResolverService();

    test('returns execution profile strategy when no override is provided', () {
      const executionProfile = ReferenceExtractionExecutionProfile(
        taskFamilyId: AgentTaskFamilies.referenceExtraction,
        executionMode: ReferenceExtractionExecutionModes.group,
        instructionProfileId: ReferenceExtractionPromptProfiles.group,
        toolPermissionProfileId:
            ReferenceExtractionToolPermissionProfiles.standard,
        strategyProfile: ReferenceExtractionStrategyProfiles.exploratory,
      );

      final resolved = service.resolve(executionProfile: executionProfile);

      expect(
        resolved.profileId,
        ReferenceExtractionBuiltinStrategyProfileIds.exploratory,
      );
    });

    test('applies builtin override when request asks for another strategy', () {
      const executionProfile = ReferenceExtractionExecutionProfile(
        taskFamilyId: AgentTaskFamilies.referenceExtraction,
        executionMode: ReferenceExtractionExecutionModes.group,
        instructionProfileId: ReferenceExtractionPromptProfiles.group,
        toolPermissionProfileId:
            ReferenceExtractionToolPermissionProfiles.standard,
      );

      final resolved = service.resolve(
        executionProfile: executionProfile,
        overrideProfileId:
            ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
      );

      expect(
        resolved.profileId,
        ReferenceExtractionBuiltinStrategyProfileIds.factFocused,
      );
      expect(
        resolved.proposalPolicy.allowedEntryKinds,
        contains(ReferenceEntryKinds.knowledgeFact),
      );
      expect(
        resolved.proposalPolicy.allowedEntryKinds,
        isNot(contains(ReferenceEntryKinds.styleTechnique)),
      );
    });

    test(
      'accepts additional custom profiles without changing resolver code',
      () {
        const executionProfile = ReferenceExtractionExecutionProfile(
          taskFamilyId: AgentTaskFamilies.referenceExtraction,
          executionMode: ReferenceExtractionExecutionModes.group,
          instructionProfileId: ReferenceExtractionPromptProfiles.group,
          toolPermissionProfileId:
              ReferenceExtractionToolPermissionProfiles.standard,
        );
        const custom = ReferenceExtractionStrategyProfile(
          profileId: 'reference_extraction.custom_dense',
          proposalPolicy: ReferenceExtractionProposalPolicy(
            minProposalCount: 6,
            maxProposalCount: 9,
          ),
        );

        final resolved = service.resolve(
          executionProfile: executionProfile,
          overrideProfileId: 'reference_extraction.custom_dense',
          additionalProfiles: <ReferenceExtractionStrategyProfile>[custom],
        );

        expect(resolved.profileId, 'reference_extraction.custom_dense');
        expect(resolved.proposalPolicy.maxProposalCount, 9);
        expect(
          resolved.outputCoverageContract.contractId,
          ReferenceExtractionOutputContracts.standard.contractId,
        );
        expect(resolved.outputCoverageContract.dimensions, isNotEmpty);
      },
    );
  });
}
