import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskToolExposureProfileResolverService', () {
    const resolver = ContinuousTaskToolExposureProfileResolverService();
    const families = ToolCapabilityFamilyCatalogService();

    test(
      'long-form writing keeps heavy extraction host-gated and defaults to mounted results',
      () {
        final taskProfile = const ContinuousTaskProfileResolverService()
            .forLongTaskMode(TaskRuntimeConstants.modeSeedToFullNovel);
        final exposureProfile = resolver.resolveForTaskProfile(taskProfile);

        expect(exposureProfile.validateBasics(), isEmpty);
        expect(exposureProfile.profileId, 'long_form_writing.default');
        expect(
          exposureProfile.defaultOpenFamilyIds,
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
            ToolCapabilityFamilyCatalogService.writing,
            ToolCapabilityFamilyCatalogService.review,
          ]),
        );
        expect(exposureProfile.requiresConfirmationFamilyIds, <String>[
          ToolCapabilityFamilyCatalogService.research,
        ]);
        expect(
          exposureProfile.hostOrSupervisorOnlyFamilyIds,
          containsAll(const <String>[
            ToolCapabilityFamilyCatalogService.referenceExtraction,
            ToolCapabilityFamilyCatalogService.referenceMountCommit,
            ToolCapabilityFamilyCatalogService.continuousTaskControl,
          ]),
        );
        expect(
          families.toolIdsForFamilies(exposureProfile.defaultOpenFamilyIds),
          isNot(contains(NarrativeDomainToolNames.proposeKnowledgeCard)),
        );
      },
    );

    test(
      'reference extraction defaults to research and heavy extraction families on the same continuous-task chain',
      () {
        final taskProfile = const ContinuousTaskProfileResolverService()
            .forReferenceExtraction();
        final exposureProfile = resolver.resolveForTaskProfile(taskProfile);
        final defaultTools = families.toolIdsForFamilies(
          exposureProfile.defaultOpenFamilyIds,
        );

        expect(exposureProfile.validateBasics(), isEmpty);
        expect(exposureProfile.profileId, 'reference_extraction.default');
        expect(
          exposureProfile.defaultOpenFamilyIds,
          containsAll(const <String>[
            ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
            ToolCapabilityFamilyCatalogService.review,
            ToolCapabilityFamilyCatalogService.research,
            ToolCapabilityFamilyCatalogService.referenceExtraction,
          ]),
        );
        expect(
          exposureProfile.hostOrSupervisorOnlyFamilyIds,
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.referenceMountCommit,
            ToolCapabilityFamilyCatalogService.continuousTaskControl,
          ]),
        );
        expect(
          defaultTools,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ]),
        );
        expect(defaultTools, isNot(contains('start_long_task_run')));
      },
    );

    test(
      'round-trips resolved exposure profile as stable production contract',
      () {
        final original = resolver.resolve(
          familyId: ContinuousTaskFamilies.goalMode,
          runKind: ContinuousTaskRunKinds.conversationLoop,
          metadata: const <String, Object?>{'objective_id': 'goal-7'},
        );

        final restored = ContinuousTaskToolExposureProfile.fromJson(
          original.toJson(),
        );

        expect(restored.validateBasics(), isEmpty);
        expect(restored.profileId, 'goal_mode.default');
        expect(restored.taskFamilyId, ContinuousTaskFamilies.goalMode);
        expect(restored.metadata['objective_id'], 'goal-7');
        expect(
          restored.requiresConfirmationFamilyIds,
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.writing,
            ToolCapabilityFamilyCatalogService.research,
          ]),
        );
      },
    );
  });
}
