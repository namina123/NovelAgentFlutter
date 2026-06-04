import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeProfileProposalService', () {
    test(
      'propose supersedes conflicting open proposals and emits audit events',
      () {
        const service = NarrativeProfileProposalService();
        final existingProposal = NarrativeProfileProposal.fromJson(
          <String, Object?>{
            'proposal_id': 'proposal-old',
            'proposal_status': 'proposed',
            'target_profile_id': 'profile-main',
            'profile_patch': <String, Object?>{
              'patch_id': 'patch-old',
              'patch_payload': <String, Object?>{
                'profile_namespace': 'project.state.main',
                'display_name': '旧解释器',
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
              },
            },
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
          },
        );
        final incomingProposal = NarrativeProfileProposal.fromJson(
          <String, Object?>{
            'proposal_id': 'proposal-new',
            'proposal_status': 'draft',
            'target_profile_id': 'profile-main',
            'profile_patch': <String, Object?>{
              'patch_id': 'patch-new',
              'patch_payload': <String, Object?>{
                'profile_namespace': 'project.state.main',
                'display_name': '新解释器',
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
              },
            },
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
            },
          },
        );

        final result = service.propose(
          proposal: incomingProposal,
          existingProposals: <NarrativeProfileProposal>[existingProposal],
        );

        expect(
          result.primaryProposal?.proposalStatus,
          NarrativeProfileLifecycleStatus.proposed,
        );
        expect(result.conflictingProposalIds, <String>['proposal-old']);
        expect(
          result.proposals
              .singleWhere((entry) => entry.proposalId == 'proposal-old')
              .proposalStatus,
          NarrativeProfileLifecycleStatus.superseded,
        );
        expect(
          result.proposals
              .singleWhere((entry) => entry.proposalId == 'proposal-old')
              .metadata['superseded_by_proposal_id'],
          'proposal-new',
        );
        expect(
          result.auditEvents.map((entry) => entry.eventType),
          containsAll(<String>['proposal_proposed', 'proposal_superseded']),
        );
      },
    );

    test(
      'accept materializes accepted profile and never jumps directly to active',
      () {
        const service = NarrativeProfileProposalService();
        final activeProfile = NarrativeProfile.fromJson(<String, Object?>{
          'profile_id': 'profile-main',
          'profile_namespace': 'project.state.main',
          'profile_label': '当前解释器',
          'lifecycle_status': 'active',
          'profile_payload': <String, Object?>{
            'claim_namespace_meanings': <String, Object?>{
              'project.state.character': '旧角色状态规则',
            },
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
          'confidence': 0.9,
        });
        final openConflict = NarrativeProfileProposal.fromJson(
          <String, Object?>{
            'proposal_id': 'proposal-conflict',
            'proposal_status': 'proposed',
            'target_profile_id': 'profile-main',
            'profile_patch': <String, Object?>{
              'patch_id': 'patch-conflict',
              'patch_payload': <String, Object?>{
                'profile_namespace': 'project.state.main',
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
              },
            },
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.writer,
            },
          },
        );
        final acceptedInput = NarrativeProfileProposal.fromJson(
          <String, Object?>{
            'proposal_id': 'proposal-accept',
            'proposal_status': 'proposed',
            'target_profile_id': 'profile-main',
            'profile_patch': <String, Object?>{
              'patch_id': 'patch-accept',
              'patch_label': '新项目解释器',
              'patch_payload': <String, Object?>{
                'profile_namespace': 'project.state.main',
                'claim_namespace_meanings': <String, Object?>{
                  'project.state.character': '新角色状态规则',
                },
              },
              'patch_extensions': <String, Object?>{
                'review_focus': <Object?>['continuity'],
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
              },
            },
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
            },
            'metadata': <String, Object?>{
              'accepted_profile_id': 'profile-main.accepted.proposal-accept',
            },
            'confidence': 0.8,
          },
        );

        final result = service.accept(
          proposal: acceptedInput,
          existingProposals: <NarrativeProfileProposal>[openConflict],
          existingProfiles: <NarrativeProfile>[activeProfile],
        );

        expect(
          result.primaryProposal?.proposalStatus,
          NarrativeProfileLifecycleStatus.accepted,
        );
        expect(
          result.primaryProfile?.lifecycleStatus,
          NarrativeProfileLifecycleStatus.accepted,
        );
        expect(
          result.primaryProfile?.profileId,
          'profile-main.accepted.proposal-accept',
        );
        expect(
          result.primaryProfile?.lifecycleStatus ==
              NarrativeProfileLifecycleStatus.active,
          isFalse,
        );
        expect(
          result.profiles
              .singleWhere((entry) => entry.profileId == 'profile-main')
              .lifecycleStatus,
          NarrativeProfileLifecycleStatus.superseded,
        );
        expect(
          result.proposals
              .singleWhere((entry) => entry.proposalId == 'proposal-conflict')
              .proposalStatus,
          NarrativeProfileLifecycleStatus.superseded,
        );
        expect(
          result.auditEvents.map((entry) => entry.eventType),
          containsAll(<String>[
            'proposal_accepted',
            'profile_superseded',
            'proposal_superseded',
          ]),
        );
      },
    );

    test('reject and explicit supersede keep clear lifecycle references', () {
      const service = NarrativeProfileProposalService();
      final proposal = NarrativeProfileProposal.fromJson(<String, Object?>{
        'proposal_id': 'proposal-review',
        'proposal_status': 'proposed',
        'profile_patch': <String, Object?>{
          'patch_id': 'patch-review',
          'patch_payload': <String, Object?>{
            'profile_namespace': 'project.review.main',
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.reviewer,
          },
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.reviewer,
        },
      });

      final rejected = service.reject(proposal: proposal);
      final superseded = service.supersede(
        proposal: proposal,
        supersededByProposalId: 'proposal-next',
        supersededByProfileId: 'profile-next',
      );

      expect(
        rejected.primaryProposal?.proposalStatus,
        NarrativeProfileLifecycleStatus.rejected,
      );
      expect(
        superseded.primaryProposal?.proposalStatus,
        NarrativeProfileLifecycleStatus.superseded,
      );
      expect(
        superseded.primaryProposal?.metadata['superseded_by_proposal_id'],
        'proposal-next',
      );
      expect(
        superseded.primaryProposal?.metadata['superseded_by_profile_id'],
        'profile-next',
      );
    });

    test('deprecate marks accepted profile as deprecated', () {
      const service = NarrativeProfileProposalService();
      final profile = NarrativeProfile.fromJson(<String, Object?>{
        'profile_id': 'profile-accepted',
        'profile_namespace': 'project.state.main',
        'lifecycle_status': 'accepted',
        'profile_payload': <String, Object?>{
          'claim_namespace_meanings': <String, Object?>{
            'project.state.main': '规则',
          },
        },
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.system},
      });

      final result = service.deprecate(profile: profile);

      expect(
        result.primaryProfile?.lifecycleStatus,
        NarrativeProfileLifecycleStatus.deprecated,
      );
      expect(result.auditEvents.single.eventType, 'profile_deprecated');
    });
  });

  group('NarrativeProfileInterpreterService', () {
    test(
      'interprets namespace meaning, minimal fields and risk hints from active profile',
      () {
        const service = NarrativeProfileInterpreterService();
        final activeProfile = NarrativeProfile.fromJson(<String, Object?>{
          'profile_id': 'profile-interpreter',
          'profile_namespace': 'project.interpreter.main',
          'profile_label': '项目解释器',
          'lifecycle_status': 'active',
          'profile_payload': <String, Object?>{
            'claim_namespace_meanings': <String, Object?>{
              'project.state.*': <String, Object?>{
                'meaning': '项目状态变更，需要进入连续性解释链。',
                'unknown_payload_preservation': '未识别字段必须原样保留，后续再决定是否赋义。',
              },
            },
            'claim_schema_hints': <String, Object?>{
              'project.state.*': <String, Object?>{
                'required_fields': <Object?>['entity_id', 'change_summary'],
              },
            },
            'risk_policy_hints': <String, Object?>{
              'project.state.*': <String, Object?>{
                'escalate_when': <Object?>['涉及跨章节持续影响时升级复核。'],
                'deescalate_when': <Object?>['仅限当前章节且证据完整时可降级。'],
              },
            },
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
        });

        final interpretation = service.interpretClaimNamespace(
          activeProfile: activeProfile,
          claimNamespace: 'project.state.character',
          claimPayload: <String, Object?>{
            'entity_id': 'hero-001',
            'change_summary': '记忆边界发生变化',
            'future_unknown_field': true,
          },
        );

        expect(interpretation.profileId, 'profile-interpreter');
        expect(interpretation.matchedRuleKey, 'project.state.*');
        expect(interpretation.namespaceMeaning, '项目状态变更，需要进入连续性解释链。');
        expect(interpretation.minimalFieldRequirements, <String>[
          'entity_id',
          'change_summary',
        ]);
        expect(interpretation.missingRequiredFields, isEmpty);
        expect(interpretation.riskEscalationSuggestions, <String>[
          '涉及跨章节持续影响时升级复核。',
        ]);
        expect(interpretation.riskDeEscalationSuggestions, <String>[
          '仅限当前章节且证据完整时可降级。',
        ]);
        expect(
          interpretation.unknownPayloadPreservationExplanation,
          '未识别字段必须原样保留，后续再决定是否赋义。',
        );
      },
    );

    test(
      'falls back to open-world explanation when profile has no exact rule',
      () {
        const service = NarrativeProfileInterpreterService();
        final activeProfile = NarrativeProfile.fromJson(<String, Object?>{
          'profile_id': 'profile-fallback',
          'profile_namespace': 'project.interpreter.fallback',
          'lifecycle_status': 'active',
          'profile_payload': <String, Object?>{},
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
        });

        final interpretation = service.interpretClaimNamespace(
          activeProfile: activeProfile,
          claimNamespace: 'project.future.unknown',
          claimPayload: <String, Object?>{'unexpected_payload': 1},
        );

        expect(interpretation.namespaceMeaning, contains('开放 claim namespace'));
        expect(
          interpretation.unknownPayloadPreservationExplanation,
          contains('原样保留'),
        );
        expect(interpretation.minimalFieldRequirements, isEmpty);
      },
    );
  });
}
