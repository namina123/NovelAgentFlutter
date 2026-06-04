import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeDomainToolCatalog', () {
    test('builds six open tool schemas without genre enums', () {
      final catalog = NarrativeDomainToolCatalog();

      final schemas = catalog.buildOpenAiSchemas();
      final joined = schemas.toString();

      expect(schemas, hasLength(6));
      expect(
        schemas
            .map(
              (schema) =>
                  ((schema['function'] as Map<String, Object?>)['name']
                      as String),
            )
            .toList(growable: false),
        NarrativeDomainToolNames.all,
      );
      expect(joined.contains('快穿'), isFalse);
      expect(joined.contains('死亡回归'), isFalse);
      expect(joined.contains('multi_world_mode'), isFalse);
    });

    test('parses all six domain tools and preserves open payloads', () {
      final catalog = NarrativeDomainToolCatalog();
      const source = NarrativeSourceRef(
        sourceType: NarrativeSourceTypes.writer,
      );

      final chapterDelivery = catalog.parseRequest(
        callId: 'call-001',
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        source: source,
        arguments: <String, Object?>{
          'chapter_path': 'chapters/第01章.md',
          'chapter_content': '# 第01章\n\n正文内容',
          'title': '第01章',
          'submission': <String, Object?>{
            'summary': '章节摘要',
            'future_sidecar_flag': true,
          },
          'future_top_level': <String, Object?>{'keep': true},
        },
      );
      final claims = catalog.parseRequest(
        callId: 'call-002',
        toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
        source: source,
        arguments: <String, Object?>{
          'source': 'writer_generated',
          'claims': <Object?>[
            <String, Object?>{
              'claim_id': 'claim-001',
              'claim_namespace': 'project.state.future',
              'claim_payload': <String, Object?>{
                'future_unknown_payload': <String, Object?>{'enabled': true},
              },
              'confidence': 0.8,
            },
          ],
          'top_level_extension': 'keep_me',
        },
      );
      final profile = catalog.parseRequest(
        callId: 'call-003',
        toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.deconstruction,
        ),
        arguments: <String, Object?>{
          'proposal_id': 'proposal-001',
          'profile_patch': <String, Object?>{
            'namespace': 'project.custom.profile',
            'display_name': '自定义解释器',
            'future_patch_payload': <String, Object?>{'layers': 3},
          },
          'requires_user_confirmation': true,
        },
      );
      final review = catalog.parseRequest(
        callId: 'call-004',
        toolName: NarrativeDomainToolNames.submitSemanticReview,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.reviewer,
        ),
        arguments: <String, Object?>{
          'review_id': 'review-001',
          'accepted_claims': <Object?>['claim-001'],
          'questioned_claims': <Object?>['claim-002'],
          'findings': <Object?>[
            <String, Object?>{
              'finding_id': 'finding-001',
              'severity': 'medium',
              'summary': '需要补证据。',
              'unable_to_locate_evidence': true,
              'unlocatable_reason': '本轮只有摘要。',
              'confidence': 0.7,
            },
          ],
          'recommended_disposition': 'repair',
        },
      );
      final binding = catalog.parseRequest(
        callId: 'call-005',
        toolName: NarrativeDomainToolNames.proposeConstraintBinding,
        source: const NarrativeSourceRef(sourceType: NarrativeSourceTypes.user),
        arguments: <String, Object?>{
          'binding_id': 'binding-001',
          'constraint_ref': 'expression_constraint.future',
          'applies_to': <Object?>['writing', 'review'],
          'hard_execution_policy': <String, Object?>{
            'ban': <Object?>['x'],
          },
          'soft_review_policy': <String, Object?>{
            'watch': <Object?>['y'],
          },
          'reason': '项目新增限制',
        },
      );
      final clarification = catalog.parseRequest(
        callId: 'call-006',
        toolName: NarrativeDomainToolNames.requestProfileClarification,
        source: source,
        arguments: <String, Object?>{
          'question': '当前规则是只作用于本章，还是后续章节都生效？',
          'options': <Object?>[
            <String, Object?>{'label': '仅本章', 'future': true},
            <String, Object?>{'title': '后续都生效'},
          ],
          'freeform_allowed': true,
          'blocking': true,
        },
      );

      expect(chapterDelivery.isSuccess, isTrue);
      expect(claims.isSuccess, isTrue);
      expect(profile.isSuccess, isTrue);
      expect(review.isSuccess, isTrue);
      expect(binding.isSuccess, isTrue);
      expect(clarification.isSuccess, isTrue);

      final chapterMetadata =
          chapterDelivery.request!.requestPayload['metadata']
              as Map<String, Object?>;
      final chapterUnknownFields =
          chapterMetadata[OpenJsonContractCodecService.unknownFieldsMetadataKey]
              as Map<String, Object?>;
      final parsedClaim =
          (claims.request!.requestPayload['claims'] as List<Object?>).single
              as Map<String, Object?>;
      final parsedProfilePatch =
          profile.request!.requestPayload['profile_patch']
              as Map<String, Object?>;
      final clarificationOptions =
          clarification.request!.requestPayload['options'] as List<Object?>;

      expect(
        (chapterUnknownFields['future_top_level']
            as Map<String, Object?>)['keep'],
        isTrue,
      );
      expect(
        (parsedClaim['source'] as Map<String, Object?>)['source_type'],
        'writer_generated',
      );
      expect(
        ((parsedClaim['claim_payload']
                as Map<String, Object?>)['future_unknown_payload']
            as Map<String, Object?>)['enabled'],
        isTrue,
      );
      expect(
        (profile.request!.requestPayload['proposal_status'] as String),
        'proposed',
      );
      expect(
        ((parsedProfilePatch['patch_payload']
                as Map<String, Object?>)['future_patch_payload']
            as Map<String, Object?>)['layers'],
        3,
      );
      expect(review.request!.requestPayload['accepted_claim_ids'], <String>[
        'claim-001',
      ]);
      expect(
        (binding.request!.requestPayload['constraint_type'] as String),
        'expression_constraint.future',
      );
      expect(
        ((clarificationOptions[1] as Map<String, Object?>)['label'] as String),
        '后续都生效',
      );
    });

    test(
      'chapter delivery keeps invalid submission for later state machine handling',
      () {
        final catalog = NarrativeDomainToolCatalog();

        final result = catalog.parseRequest(
          callId: 'call-007',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: const NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.writer,
          ),
          arguments: <String, Object?>{
            'chapter_path': 'chapters/第02章.md',
            'chapter_content': '# 第02章\n\n正文内容',
            'submission': <String, Object?>{
              'submission_id': '',
              'chapter_ref': <String, Object?>{},
            },
          },
        );

        expect(result.isSuccess, isTrue);
        expect(
          ((result.request!.requestPayload['metadata']
                      as Map<String, Object?>)['submission_validation_errors']
                  as List<Object?>)
              .isNotEmpty,
          isTrue,
        );
      },
    );

    test('returns structured issues for malformed payloads', () {
      final catalog = NarrativeDomainToolCatalog();

      final malformedDelivery = catalog.parseRequest(
        callId: 'call-008',
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.writer,
        ),
        arguments: <String, Object?>{
          'chapter_content': '# 第03章',
          'submission': 'not-a-map',
        },
      );
      final malformedClarification = catalog.parseRequest(
        callId: 'call-009',
        toolName: NarrativeDomainToolNames.requestProfileClarification,
        source: const NarrativeSourceRef(
          sourceType: NarrativeSourceTypes.writer,
        ),
        arguments: <String, Object?>{
          'question': '请选择规则',
          'options': <Object?>[
            <String, Object?>{'id': 'opt-1'},
          ],
        },
      );

      expect(malformedDelivery.isSuccess, isFalse);
      expect(
        malformedDelivery.issues.map((issue) => issue.code),
        contains(NarrativeDomainToolValidationCodes.missingRequiredField),
      );
      expect(
        malformedClarification.issues.single.fieldPath,
        'options[0].label',
      );
    });
  });
}
