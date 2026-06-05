import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('InformationLifecycleService', () {
    test(
      'links connect knowledge design research reference and claim refs',
      () {
        const service = InformationLifecycleService();
        final knowledgeToDesign = service.createLink(
          link: InformationLink.fromJson(<String, Object?>{
            'link_id': 'link-001',
            'link_type': 'supports_design',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.knowledgeCard,
              'ref_id': 'knowledge-001',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.designElement,
              'ref_id': 'design-001',
            },
            'created_by': 'writer.agent',
          }),
        );
        final researchToReference = service.createLink(
          link: InformationLink.fromJson(<String, Object?>{
            'link_id': 'link-002',
            'link_type': 'documents_boundary',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.researchNote,
              'ref_id': 'research-001',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.referenceWork,
              'ref_id': 'reference-001',
            },
          }),
        );
        final referenceToClaim = service.createLink(
          link: InformationLink.fromJson(<String, Object?>{
            'link_id': 'link-003',
            'link_type': 'constrains_claim',
            'source_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.referenceWork,
              'ref_id': 'reference-001',
            },
            'target_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.narrativeClaim,
              'ref_id': 'claim-001',
            },
            'future_extension': <String, Object?>{'preserve': true},
          }),
        );

        expect(knowledgeToDesign.validateBasics(), isEmpty);
        expect(researchToReference.validateBasics(), isEmpty);
        expect(referenceToClaim.validateBasics(), isEmpty);
        expect(
          knowledgeToDesign.sourceRef.refType,
          InformationLinkedRefTypes.knowledgeCard,
        );
        expect(
          researchToReference.targetRef.refType,
          InformationLinkedRefTypes.referenceWork,
        );
        expect(
          referenceToClaim.targetRef.refType,
          InformationLinkedRefTypes.narrativeClaim,
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              referenceToClaim.toJson()['future_extension'],
            )['preserve'],
          ),
          isTrue,
        );
      },
    );

    test(
      'propose accept question reject flow stays auditable for user reviewer and system',
      () {
        const service = InformationLifecycleService();
        final subjectRef = NarrativeRef.fromJson(<String, Object?>{
          'ref_type': InformationLinkedRefTypes.knowledgeCard,
          'ref_id': 'knowledge-002',
        });
        final supportingLink = InformationLink.fromJson(<String, Object?>{
          'link_id': 'link-101',
          'link_type': 'derived_from_research',
          'source_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.researchNote,
            'ref_id': 'research-002',
          },
          'target_ref': <String, Object?>{
            'ref_type': InformationLinkedRefTypes.knowledgeCard,
            'ref_id': 'knowledge-002',
          },
        });

        final proposed = service.propose(
          subjectRef: subjectRef,
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'writer_role',
            'ref_id': 'writer-primary',
          }),
          links: <InformationLink>[supportingLink],
          eventId: 'event-proposed',
          summary: 'writer 提交新的项目知识候选。',
        );
        final accepted = service.accept(
          status: proposed.primaryStatus!,
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'user_role',
            'ref_id': 'user-owner',
          }),
          eventId: 'event-accepted',
        );
        final questioned = service.question(
          status: accepted.primaryStatus!,
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'reviewer_role',
            'ref_id': 'reviewer-1',
          }),
          eventId: 'event-questioned',
        );
        final rejected = service.reject(
          status: questioned.primaryStatus!,
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'system_role',
            'ref_id': 'system-audit',
          }),
          eventId: 'event-rejected',
        );

        expect(
          proposed.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.proposed,
        );
        expect(
          accepted.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.accepted,
        );
        expect(
          questioned.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.questioned,
        );
        expect(
          rejected.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.rejected,
        );
        expect(proposed.emittedLinks.single.linkId, 'link-101');
        expect(proposed.emittedEvents.single.relatedLinkIds, <String>[
          'link-101',
        ]);
        expect(accepted.emittedEvents.single.actorRef.refType, 'user_role');
        expect(
          questioned.emittedEvents.single.actorRef.refType,
          'reviewer_role',
        );
        expect(rejected.emittedEvents.single.actorRef.refType, 'system_role');
      },
    );

    test(
      'supersede and deprecate keep clear references without reading payload meaning',
      () {
        const service = InformationLifecycleService();
        final acceptedStatus = InformationLifecycleStatus.fromJson(
          <String, Object?>{
            'subject_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.designElement,
              'ref_id': 'design-007',
            },
            'lifecycle_status': InformationLifecycleStatuses.accepted,
            'last_event_id': 'event-accepted-007',
          },
        );

        final superseded = service.supersede(
          status: acceptedStatus,
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'user_role',
            'ref_id': 'user-owner',
          }),
          supersededByRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': InformationLinkedRefTypes.designElement,
            'ref_id': 'design-008',
          }),
          eventId: 'event-superseded-007',
        );
        final deprecated = service.deprecate(
          status: InformationLifecycleStatus.fromJson(<String, Object?>{
            'subject_ref': <String, Object?>{
              'ref_type': InformationLinkedRefTypes.referenceWork,
              'ref_id': 'reference-009',
            },
            'lifecycle_status': InformationLifecycleStatuses.accepted,
            'last_event_id': 'event-accepted-009',
          }),
          actorRef: NarrativeRef.fromJson(<String, Object?>{
            'ref_type': 'system_role',
            'ref_id': 'system-policy',
          }),
          eventId: 'event-deprecated-009',
        );

        expect(
          superseded.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.superseded,
        );
        expect(superseded.primaryStatus?.supersededByRef?.refId, 'design-008');
        expect(
          superseded.emittedEvents.single.relatedRefs.single.refId,
          'design-008',
        );
        expect(
          deprecated.primaryStatus?.lifecycleStatus,
          InformationLifecycleStatuses.deprecated,
        );
        expect(
          deprecated.emittedEvents.single.eventType,
          'information_deprecated',
        );
      },
    );

    test('invalid refs fail validation without semantic interpretation', () {
      final invalidLink = InformationLink.fromJson(<String, Object?>{
        'link_id': '',
        'link_type': '',
        'source_ref': <String, Object?>{'ref_type': '', 'ref_id': ''},
        'target_ref': <String, Object?>{'ref_type': '', 'ref_id': ''},
      });
      final invalidEvent = InformationEvent.fromJson(<String, Object?>{
        'event_id': '',
        'event_type': '',
        'subject_ref': <String, Object?>{'ref_type': '', 'ref_id': ''},
        'lifecycle_status': '',
        'actor_ref': <String, Object?>{'ref_type': '', 'ref_id': ''},
      });
      final invalidStatus = InformationLifecycleStatus.fromJson(
        <String, Object?>{
          'subject_ref': <String, Object?>{'ref_type': '', 'ref_id': ''},
          'lifecycle_status': '',
        },
      );

      expect(
        invalidLink.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationLinkId,
          InformationValidationCodes.missingInformationLinkType,
          InformationValidationCodes.missingInformationLinkSourceRef,
          InformationValidationCodes.missingInformationLinkTargetRef,
        ]),
      );
      expect(
        invalidEvent.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationEventId,
          InformationValidationCodes.missingInformationEventType,
          InformationValidationCodes.missingInformationEventSubjectRef,
          InformationValidationCodes.missingInformationEventLifecycleStatus,
          InformationValidationCodes.missingInformationEventActorRef,
        ]),
      );
      expect(
        invalidStatus.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingInformationLifecycleSubjectRef,
          InformationValidationCodes.missingInformationLifecycleStatus,
        ]),
      );
    });
  });
}
