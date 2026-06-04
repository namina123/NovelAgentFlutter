import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeProfile contracts', () {
    test('profile preserves lifecycle status and unknown extensions', () {
      const codec = NarrativeProfileCodecService();
      final profile = codec.profileFromJson(<String, Object?>{
        'profile_id': 'profile-001',
        'profile_namespace': 'project.interpreter.main',
        'profile_label': '项目解释器',
        'lifecycle_status': 'active',
        'profile_payload': <String, Object?>{
          'focus': 'continuity',
        },
        'profile_extensions': <String, Object?>{
          'legacy_mechanic_profile': <String, Object?>{
            'identity_mode': 'forked_alias',
            'visibility_mode': 'meta_only',
          },
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.system,
          'source_id': 'system-profile-seed',
        },
        'confidence': 0.9,
        'reason': '系统初始化',
        'schema_version': 'ons-05',
      });

      final encoded = codec.profileToJson(profile);

      expect(profile.lifecycleStatus, NarrativeProfileLifecycleStatus.active);
      expect(profile.validateBasics(), isEmpty);
      expect(
        ((encoded['profile_extensions'] as Map<String, Object?>)['legacy_mechanic_profile']
            as Map<String, Object?>)['identity_mode'],
        'forked_alias',
      );
    });

    test('patch remains open and round-trips unknown payload', () {
      const codec = NarrativeProfileCodecService();
      final patch = codec.patchFromJson(<String, Object?>{
        'patch_id': 'patch-001',
        'patch_label': '补充项目规则',
        'patch_payload': <String, Object?>{
          'custom_rule': <String, Object?>{
            'name': 'unknown.future.rule',
            'enabled': true,
          },
        },
        'patch_extensions': <String, Object?>{
          'notes': <Object?>['a', 'b'],
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.writer,
        },
        'confidence': 0.6,
      });

      final encoded = codec.patchToJson(patch);

      expect(patch.validateBasics(), isEmpty);
      expect(
        (((encoded['patch_payload'] as Map<String, Object?>)['custom_rule']
                as Map<String, Object?>)['name']),
        'unknown.future.rule',
      );
      expect(
        ((encoded['patch_extensions'] as Map<String, Object?>)['notes']
                as List<Object?>)
            .length,
        2,
      );
    });

    test('proposal cannot represent implicit direct overwrite of accepted rules', () {
      const codec = NarrativeProfileCodecService();
      final proposal = codec.proposalFromJson(<String, Object?>{
        'proposal_id': 'proposal-001',
        'proposal_status': 'accepted',
        'profile_patch': <String, Object?>{
          'patch_id': 'patch-002',
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.reviewer,
          },
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.reviewer,
        },
        'requires_user_confirmation': true,
        'confidence': 0.7,
      });

      expect(
        proposal.validateBasics(),
        contains(
          NarrativeProfileValidationCodes.invalidProposalStatusForDirectApply,
        ),
      );
    });

    test('proposal round-trips proposed status and confirmation fields', () {
      const codec = NarrativeProfileCodecService();
      final proposal = codec.proposalFromJson(<String, Object?>{
        'proposal_id': 'proposal-002',
        'proposal_status': 'proposed',
        'target_profile_id': 'profile-001',
        'base_profile_id': 'profile-base-001',
        'profile_patch': <String, Object?>{
          'patch_id': 'patch-003',
          'patch_payload': <String, Object?>{
            'memory_visibility': 'scoped',
          },
          'source': <String, Object?>{
            'source_type': 'future.profile_architect',
          },
        },
        'source': <String, Object?>{
          'source_type': 'future.profile_architect',
        },
        'requires_user_confirmation': true,
        'reason': '涉及长期项目规则变更',
        'confidence': 0.8,
        'schema_version': 'ons-05',
      });

      final encoded = codec.proposalToJson(proposal);

      expect(proposal.proposalStatus, NarrativeProfileLifecycleStatus.proposed);
      expect(proposal.requiresUserConfirmation, isTrue);
      expect(proposal.validateBasics(), isEmpty);
      expect(encoded['proposal_status'], 'proposed');
      expect(encoded['requires_user_confirmation'], isTrue);
      expect(
        (((encoded['profile_patch'] as Map<String, Object?>)['patch_payload']
                as Map<String, Object?>)['memory_visibility']),
        'scoped',
      );
    });
  });
}
