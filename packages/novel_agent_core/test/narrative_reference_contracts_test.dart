import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative reference contracts', () {
    test('source ref preserves unknown source type during round-trip', () {
      final source = NarrativeSourceRef.fromJson(<String, Object?>{
        'source_type': 'custom_source.future_agent',
        'source_id': 'source-001',
        'label': '未来来源',
        'description': '保留未知来源字符串',
        'metadata': <String, Object?>{'confidence_hint': 'low'},
      });

      expect(source.sourceType, 'custom_source.future_agent');
      expect(source.sourceKind, 'custom_source.future_agent');
      expect(source.sourceAssetId, 'source-001');
      expect(source.displayName, '未来来源');
      expect(source.toJson()['source_type'], 'custom_source.future_agent');
      expect(source.toJson()['source_asset_id'], 'source-001');
      expect(
        (source.toJson()['metadata']
            as Map<String, Object?>)['confidence_hint'],
        'low',
      );
    });

    test('narrative ref and evidence ref preserve open ref types', () {
      final evidence = NarrativeEvidenceRef.fromJson(<String, Object?>{
        'evidence_type': NarrativeEvidenceTypes.toolCall,
        'evidence_id': 'evidence-001',
        'source_ref': <String, Object?>{
          'source_type': NarrativeSourceTypes.writer,
          'source_id': 'writer-001',
          'resolver_uri': 'agent://writer/writer-001',
        },
        'target_ref': <String, Object?>{
          'ref_type': 'tool_round_extension',
          'ref_id': 'tool-round-001',
          'relative_path': '.novel_agent/runtime/tool_rounds/001.json',
          'metadata': <String, Object?>{'provider': 'mock'},
        },
        'text_span': <String, Object?>{
          'target_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-001',
            'relative_path': 'chapters/第01章.md',
          },
          'start_offset': 12,
          'end_offset': 48,
          'start_line': 2,
          'end_line': 4,
          'excerpt': '这是证据摘录。',
        },
        'summary': '记录工具轮证据。',
        'metadata': <String, Object?>{'accepted': true},
      });

      expect(evidence.evidenceType, NarrativeEvidenceTypes.toolCall);
      expect(evidence.sourceRef!.sourceType, NarrativeSourceTypes.writer);
      expect(evidence.sourceRef!.resolverUri, 'agent://writer/writer-001');
      expect(evidence.targetRef!.refType, 'tool_round_extension');
      expect(evidence.textSpan!.targetRef.refType, NarrativeRefTypes.chapter);
      expect(
        evidence.toJson()['evidence_type'],
        NarrativeEvidenceTypes.toolCall,
      );
      expect(
        ((evidence.toJson()['target_ref'] as Map<String, Object?>)['metadata']
            as Map<String, Object?>)['provider'],
        'mock',
      );
    });

    test(
      'tool round evidence supports asset segment and external snippet refs',
      () {
        final toolRoundEvidence = ToolRoundEvidence.fromJson(<String, Object?>{
          'tool_round_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.toolRound,
            'ref_id': 'tool-round-002',
          },
          'tool_call_ids': <Object?>['call-001', 'call-002'],
          'transcript_message_ids': <Object?>['msg-001'],
          'evidence_refs': <Object?>[
            <String, Object?>{
              'evidence_type': NarrativeEvidenceTypes.assistantTranscript,
              'evidence_id': 'evidence-002',
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.segment,
                'ref_id': 'segment-001',
                'chapter_id': 'chapter-001',
                'segment_id': 'segment-001',
              },
            },
            <String, Object?>{
              'evidence_type': NarrativeEvidenceTypes.extractedSnippet,
              'evidence_id': 'evidence-003',
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.externalImportSnippet,
                'ref_id': 'import-snippet-001',
                'source_path': 'imports/source-book/chapter-12.txt',
              },
            },
            <String, Object?>{
              'evidence_type': NarrativeEvidenceTypes.reviewNote,
              'evidence_id': 'evidence-004',
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.asset,
                'ref_id': 'character:hero',
                'metadata': <String, Object?>{
                  'asset_kind': 'character_profile',
                },
              },
            },
          ],
        });

        expect(
          toolRoundEvidence.toolRoundRef.refType,
          NarrativeRefTypes.toolRound,
        );
        expect(toolRoundEvidence.evidenceRefs, hasLength(3));
        expect(
          toolRoundEvidence.evidenceRefs[0].targetRef!.refType,
          NarrativeRefTypes.segment,
        );
        expect(
          toolRoundEvidence.evidenceRefs[1].targetRef!.refType,
          NarrativeRefTypes.externalImportSnippet,
        );
        expect(
          toolRoundEvidence.evidenceRefs[2].targetRef!.refType,
          NarrativeRefTypes.asset,
        );
        expect(
          (toolRoundEvidence.toJson()['tool_call_ids'] as List<Object?>).length,
          2,
        );
      },
    );
  });
}
