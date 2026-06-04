import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeConstraintBindingProposal contracts', () {
    test('word count policy preserves familiar user-facing semantics', () {
      const codec = NarrativeConstraintBindingCodecService();
      final proposal = codec.proposalFromJson(<String, Object?>{
        'binding_id': 'binding-length-001',
        'constraint_type': 'chapter_length',
        'constraint_id': 'length-profile-main',
        'constraint_label': '目标字数',
        'constraint_origin': 'project',
        'constraint_payload': <String, Object?>{
          'target_word_count': 2600,
          'preferred_min': 2300,
          'preferred_max': 2900,
          'metric_unit': 'visible_characters',
        },
        'binding_scope': <String, Object?>{
          'applies_to': <Object?>[
            ConstraintBindingAppliesTo.writing,
            ConstraintBindingAppliesTo.repair,
          ],
          'stage_ids': <Object?>['draft'],
        },
        'binding_policy': <String, Object?>{
          'hard_execution_policy': <String, Object?>{
            'target_word_count': 2600,
            'overflow_tolerance': 120,
          },
          'soft_review_policy': <String, Object?>{
            'warn_if_below': 2300,
            'warn_if_above': 2900,
          },
          'auto_accept': true,
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.user,
          'source_id': 'user-setting',
        },
        'reason': '项目要求章节长度稳定。',
        'confidence': 0.95,
        'schema_version': 'ons-09',
      });

      final encoded = codec.proposalToJson(proposal);
      final payload = encoded['constraint_payload'] as Map<String, Object?>;
      final policy = encoded['binding_policy'] as Map<String, Object?>;

      expect(proposal.validateBasics(), isEmpty);
      expect(proposal.constraintLabel, '目标字数');
      expect(payload['target_word_count'], 2600);
      expect(
        (policy['hard_execution_policy']
            as Map<String, Object?>)['overflow_tolerance'],
        120,
      );
    });

    test(
      'expression constraint binding distinguishes built-in and project level',
      () {
        const codec = NarrativeConstraintBindingCodecService();
        final proposal = codec.proposalFromJson(<String, Object?>{
          'binding_id': 'binding-expression-001',
          'constraint_type': 'expression_constraint',
          'constraint_id': 'builtin-natural-expression',
          'constraint_label': '表达限制',
          'constraint_origin': 'builtin',
          'constraint_payload': <String, Object?>{
            'profile_id': 'natural-expression-v2',
            'project_level_rules': <Object?>['避免模板化总结句', '收束段保持角色视角内感'],
            'built_in_profile': true,
          },
          'binding_scope': <String, Object?>{
            'applies_to': <Object?>[
              ConstraintBindingAppliesTo.writing,
              ConstraintBindingAppliesTo.review,
            ],
            'agent_ids': <Object?>['writer', 'reviewer'],
          },
          'binding_policy': <String, Object?>{
            'soft_review_policy': <String, Object?>{
              'check_authenticity_pass': 'medium',
              'project_rule_layer': 'project',
            },
            'requires_user_confirmation': true,
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
          'confidence': 0.8,
        });

        expect(proposal.validateBasics(), isEmpty);
        expect(proposal.constraintOrigin, 'builtin');
        expect(
          (proposal.constraintPayload['project_level_rules'] as List<Object?>)
              .length,
          2,
        );
        expect(proposal.policy.requiresUserConfirmation, isTrue);
      },
    );

    test(
      'unknown constraint type and nested policies round-trip unchanged',
      () {
        const codec = NarrativeConstraintBindingCodecService();
        final proposal = codec.proposalFromJson(<String, Object?>{
          'binding_id': 'binding-future-001',
          'constraint_type': 'future.experimental.constraint',
          'constraint_label': '未来约束',
          'constraint_payload': <String, Object?>{
            'rule_family': 'unknown.future.family',
            'nested_policy': <String, Object?>{
              'level': 3,
              'flags': <Object?>['alpha', 'beta'],
            },
          },
          'scope': <String, Object?>{
            'applies_to': <Object?>[ConstraintBindingAppliesTo.explanation],
            'mode_ids': <Object?>['analysis'],
          },
          'hard_execution_policy': <String, Object?>{
            'allow_partial_projection': true,
          },
          'soft_review_policy': <String, Object?>{
            'notes': <Object?>['preserve_unknown_payload'],
          },
          'source': <String, Object?>{
            'source_type': 'future.constraint_architect',
          },
          'confidence': 0.6,
        });

        final encoded = codec.proposalToJson(proposal);

        expect(proposal.validateBasics(), isEmpty);
        expect(proposal.constraintType, 'future.experimental.constraint');
        expect(
          ((encoded['constraint_payload']
                      as Map<String, Object?>)['nested_policy']
                  as Map<String, Object?>)['flags']
              as List<Object?>,
          contains('beta'),
        );
        expect(
          (((encoded['binding_policy']
                      as Map<String, Object?>)['soft_review_policy']
                  as Map<String, Object?>)['notes'])
              as List<Object?>,
          contains('preserve_unknown_payload'),
        );
      },
    );

    test(
      'validation reports missing applies_to and conflicting permission flags',
      () {
        final proposal = NarrativeConstraintBindingProposal.fromJson(
          <String, Object?>{
            'binding_id': '',
            'constraint_type': '',
            'binding_scope': <String, Object?>{},
            'binding_policy': <String, Object?>{
              'auto_accept': true,
              'requires_user_confirmation': true,
            },
            'source': <String, Object?>{},
            'confidence': 1.2,
          },
        );

        expect(
          proposal.validateBasics(),
          containsAll(<String>[
            NarrativeConstraintBindingValidationCodes.missingBindingId,
            NarrativeConstraintBindingValidationCodes.missingConstraintType,
            NarrativeConstraintBindingValidationCodes.missingSourceType,
            NarrativeConstraintBindingValidationCodes.missingAppliesTo,
            NarrativeConstraintBindingValidationCodes.invalidConfidence,
            NarrativeConstraintBindingValidationCodes
                .conflictingPermissionDisposition,
          ]),
        );
      },
    );
  });
}
