import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskToolExposureRuntimeResolverService', () {
    const resolver = ContinuousTaskToolExposureRuntimeResolverService();

    test(
      'writing task with writing group keeps research visible but not default-open',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[
            NarrativeDomainToolNames.submitChapterDelivery,
            NarrativeDomainToolNames.submitSemanticReview,
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            'read_project_file',
          ],
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'writing_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
          runtimeContext: const <String, Object?>{'task_type': 'chapter'},
          intent: 'workflow_task',
          explicitTaskFamilyId: ContinuousTaskFamilies.longFormWriting,
        );

        expect(
          resolution.defaultOpenCapabilityFamilyIds,
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
            ToolCapabilityFamilyCatalogService.writing,
            ToolCapabilityFamilyCatalogService.review,
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.submitChapterDelivery,
            NarrativeDomainToolNames.submitSemanticReview,
            'read_project_file',
          ]),
        );
        expect(
          resolution.requiresConfirmationToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
          ]),
        );
        expect(
          resolution.visibleToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
          ]),
        );
        expect(
          resolution.visibleToolIds,
          isNot(
            containsAll(const <String>[
              NarrativeDomainToolNames.proposeKnowledgeCard,
              NarrativeDomainToolNames.proposeDesignElement,
              NarrativeDomainToolNames.linkInformationEvidence,
              NarrativeDomainToolNames.proposeReferenceWork,
            ]),
          ),
        );
      },
    );

    test(
      'reference extraction task with extraction group keeps heavy extraction families open',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[
            NarrativeDomainToolNames.submitChapterDelivery,
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ],
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'reference_extraction_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
                ToolCapabilityFamilyCatalogService.referenceExtraction,
              ],
            },
          },
          runtimeContext: const <String, Object?>{
            'task_type': 'chapter',
            'task_family_id': ContinuousTaskFamilies.referenceExtraction,
          },
          intent: 'workflow_task',
        );

        expect(
          resolution.taskProfile.familyId,
          ContinuousTaskFamilies.referenceExtraction,
        );
        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
      },
    );

    test(
      'reference extraction task with writing group keeps research tools but prunes heavy extraction tools',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
            'read_project_file',
          ],
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'writing_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
          runtimeContext: const <String, Object?>{
            'task_type': 'chapter',
            'task_family_id': ContinuousTaskFamilies.referenceExtraction,
          },
          intent: 'workflow_task',
        );

        expect(
          resolution.defaultOpenCapabilityFamilyIds,
          orderedEquals(const <String>[
            ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
            ToolCapabilityFamilyCatalogService.review,
            ToolCapabilityFamilyCatalogService.research,
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
            'read_project_file',
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          isNot(
            containsAll(const <String>[
              NarrativeDomainToolNames.proposeKnowledgeCard,
              NarrativeDomainToolNames.proposeDesignElement,
              NarrativeDomainToolNames.linkInformationEvidence,
              NarrativeDomainToolNames.proposeReferenceWork,
            ]),
          ),
        );
      },
    );

    test(
      'research task type infers research consolidation family and prioritizes research tools',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[],
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'research_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
                ToolCapabilityFamilyCatalogService.referenceExtraction,
              ],
            },
          },
          runtimeContext: const <String, Object?>{'task_type': 'research'},
          intent: 'workflow_task',
        );

        expect(
          resolution.taskProfile.familyId,
          ContinuousTaskFamilies.researchConsolidation,
        );
        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.requestExternalResearch,
            NarrativeDomainToolNames.submitResearchNote,
          ]),
        );
        expect(
          resolution.visibleToolIds,
          contains(NarrativeDomainToolNames.requestExternalResearch),
        );
        expect(
          resolution.defaultAllowedToolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
      },
    );

    test(
      'planning task keeps planning file tools but excludes formal chapter delivery',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[],
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'writing_room',
            'metadata': <String, Object?>{
              'tool_capability_family_ids': <String>[
                ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
                ToolCapabilityFamilyCatalogService.writing,
                ToolCapabilityFamilyCatalogService.review,
                ToolCapabilityFamilyCatalogService.research,
              ],
            },
          },
          runtimeContext: const <String, Object?>{'task_type': 'planning'},
          intent: 'workflow_task',
          explicitTaskFamilyId: ContinuousTaskFamilies.longFormWriting,
        );

        expect(
          resolution.defaultAllowedToolIds,
          containsAll(const <String>[
            NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
            NarrativeDomainToolNames.requestProfileClarification,
            'read_project_file',
            'write_project_file',
            'edit_project_file',
          ]),
        );
        expect(
          resolution.defaultAllowedToolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
      },
    );

    test(
      'review task prunes formal delivery and user-choice tools from default exposure',
      () {
        final resolution = resolver.resolve(
          candidateToolIds: const <String>[],
          runtimeContext: const <String, Object?>{
            'task_type': 'review',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          },
          intent: 'workflow_task',
          explicitTaskFamilyId: ContinuousTaskFamilies.longFormWriting,
        );

        expect(
          resolution.visibleToolIds,
          contains(NarrativeDomainToolNames.submitSemanticReview),
        );
        expect(
          resolution.visibleToolIds,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
        expect(
          resolution.visibleToolIds,
          isNot(contains('present_user_options')),
        );
        expect(
          resolution.visibleToolIds,
          isNot(
            contains(NarrativeDomainToolNames.proposeNarrativeProfileUpdate),
          ),
        );
      },
    );
  });
}
