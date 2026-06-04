import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeStateClaim contracts', () {
    test(
      'preserves unknown namespace and nested payload during round-trip',
      () {
        const codec = NarrativeStateClaimCodecService();
        final claim = codec.fromJson(<String, Object?>{
          'claim_id': 'claim-001',
          'claim_namespace': 'custom.genre.unbounded',
          'claim_label': '未知设定变化',
          'claim_payload': <String, Object?>{
            'world_state': <String, Object?>{
              'phase': 'folded',
              'layers': <Object?>[
                <String, Object?>{'id': 'layer-a', 'visible': true},
                <String, Object?>{'id': 'layer-b', 'visible': false},
              ],
            },
            'notes': <Object?>['alpha', 'beta'],
          },
          'affected_refs': <Object?>[
            <String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-001',
              'relative_path': 'chapters/第01章.md',
            },
          ],
          'context_refs': <Object?>[
            <String, Object?>{
              'ref_type': NarrativeRefTypes.segment,
              'ref_id': 'segment-001',
              'chapter_id': 'chapter-001',
              'segment_id': 'segment-001',
            },
          ],
          'evidence_refs': <Object?>[
            <String, Object?>{
              'evidence_type': NarrativeEvidenceTypes.toolCall,
              'evidence_id': 'evidence-001',
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-001',
              },
            },
          ],
          'source': <String, Object?>{
            'source_type': 'future.synthetic_reviewer',
            'source_id': 'source-001',
          },
          'future_top_level': <String, Object?>{
            'enabled': true,
            'notes': <Object?>['x'],
          },
          'confidence': 0.75,
          'uncertainty': '仍需后续章节确认',
          'schema_version': 'ons-04',
        });

        final encoded = codec.toJson(claim);

        expect(claim.claimNamespace, 'custom.genre.unbounded');
        expect(claim.source.sourceType, 'future.synthetic_reviewer');
        expect(encoded['claim_namespace'], 'custom.genre.unbounded');
        expect(
          (((encoded['future_top_level'] as Map<String, Object?>)['enabled'])),
          isTrue,
        );
        expect(
          (((encoded['claim_payload'] as Map<String, Object?>)['world_state']
                      as Map<String, Object?>)['layers']
                  as List<Object?>)
              .length,
          2,
        );
        expect(claim.metadata, isNotEmpty);
        expect(claim.validateBasics(), isEmpty);
      },
    );

    test('copyWith preserves open payload while allowing targeted updates', () {
      final base = NarrativeStateClaim.fromJson(<String, Object?>{
        'claim_id': 'claim-002',
        'claim_namespace': 'analysis.namespace',
        'claim_payload': <String, Object?>{
          'nested': <String, Object?>{'value': 1},
        },
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.deconstruction,
        },
        'confidence': 0.4,
      });

      final updated = base.copyWith(claimLabel: '分析结论', confidence: 0.9);

      expect(updated.claimId, 'claim-002');
      expect(updated.claimLabel, '分析结论');
      expect(updated.confidence, 0.9);
      expect(
        ((updated.claimPayload['nested'] as Map<String, Object?>)['value']),
        1,
      );
    });

    test('codec service supports empty claim lists', () {
      const codec = NarrativeStateClaimCodecService();

      expect(codec.fromJsonList(const <Object?>[]), isEmpty);
      expect(codec.toJsonList(const <NarrativeStateClaim>[]), isEmpty);
    });

    test(
      'validation basics report missing identity and invalid confidence',
      () {
        final claim = NarrativeStateClaim.fromJson(<String, Object?>{
          'claim_id': '',
          'claim_namespace': '',
          'claim_payload': <String, Object?>{},
          'source': <String, Object?>{},
          'confidence': 1.5,
        });

        expect(
          claim.validateBasics(),
          containsAll(<String>[
            NarrativeStateClaimValidationCodes.missingClaimId,
            NarrativeStateClaimValidationCodes.missingClaimNamespace,
            NarrativeStateClaimValidationCodes.missingSourceType,
            NarrativeStateClaimValidationCodes.invalidConfidence,
          ]),
        );
      },
    );
  });
}
