import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeEvidenceResolverService', () {
    test('resolves valid span against provided in-memory text snapshot', () {
      const service = NarrativeEvidenceResolverService();
      final evidence = _buildEvidenceRef(
        textSpan: <String, Object?>{
          'target_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-001',
            'relative_path': 'chapters/第01章.md',
          },
          'start_offset': 0,
          'end_offset': 5,
          'start_line': 1,
          'end_line': 1,
          'excerpt': '第一段',
        },
      );
      final resolution = service.resolve(
        evidenceRef: evidence,
        textSnapshots: <NarrativeEvidenceTextSnapshot>[
          NarrativeEvidenceTextSnapshot(
            snapshotId: 'snapshot-001',
            label: 'chapter text',
            targetRef: NarrativeRef.fromJson(<String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-001',
              'relative_path': 'chapters/第01章.md',
            }),
            text: '第一段内容\n第二段内容',
          ),
        ],
      );

      expect(resolution.status, NarrativeEvidenceResolutionStatuses.resolved);
      expect(resolution.snapshotId, 'snapshot-001');
      expect(resolution.lineCount, 2);
      expect(resolution.excerptMatched, isTrue);
    });

    test('returns unresolved when target text is not provided', () {
      const service = NarrativeEvidenceResolverService();
      final evidence = _buildEvidenceRef(
        textSpan: <String, Object?>{
          'target_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-002',
          },
          'start_offset': 0,
          'end_offset': 10,
        },
      );

      final resolution = service.resolve(evidenceRef: evidence);

      expect(resolution.status, NarrativeEvidenceResolutionStatuses.unresolved);
      expect(resolution.message, contains('unresolved'));
    });

    test('returns missing when evidence ref does not include text span', () {
      const service = NarrativeEvidenceResolverService();
      final evidence = NarrativeEvidenceRef.fromJson(<String, Object?>{
        'evidence_type': NarrativeEvidenceTypes.reviewNote,
        'evidence_id': 'evidence-missing',
        'target_ref': <String, Object?>{
          'ref_type': NarrativeRefTypes.chapter,
          'ref_id': 'chapter-003',
        },
      });

      final resolution = service.resolve(evidenceRef: evidence);

      expect(resolution.status, NarrativeEvidenceResolutionStatuses.missing);
    });

    test('returns ambiguous when multiple snapshots match the same ref', () {
      const service = NarrativeEvidenceResolverService();
      final evidence = _buildEvidenceRef(
        textSpan: <String, Object?>{
          'target_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-004',
          },
          'start_offset': 0,
          'end_offset': 3,
        },
      );

      final resolution = service.resolve(
        evidenceRef: evidence,
        textSnapshots: <NarrativeEvidenceTextSnapshot>[
          NarrativeEvidenceTextSnapshot(
            snapshotId: 'snapshot-a',
            targetRef: NarrativeRef.fromJson(<String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-004',
            }),
            text: '甲乙丙',
          ),
          NarrativeEvidenceTextSnapshot(
            snapshotId: 'snapshot-b',
            targetRef: NarrativeRef.fromJson(<String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-004',
            }),
            text: '丁戊己',
          ),
        ],
      );

      expect(resolution.status, NarrativeEvidenceResolutionStatuses.ambiguous);
      expect(resolution.matchedSnapshotCount, 2);
    });

    test('returns out_of_range when offsets exceed text length', () {
      const service = NarrativeEvidenceResolverService();
      final evidence = _buildEvidenceRef(
        textSpan: <String, Object?>{
          'target_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-005',
          },
          'start_offset': 3,
          'end_offset': 99,
          'start_line': 1,
          'end_line': 4,
        },
      );

      final resolution = service.resolve(
        evidenceRef: evidence,
        textSnapshots: <NarrativeEvidenceTextSnapshot>[
          NarrativeEvidenceTextSnapshot(
            snapshotId: 'snapshot-005',
            targetRef: NarrativeRef.fromJson(<String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapter-005',
            }),
            text: '短文本',
          ),
        ],
      );

      expect(resolution.status, NarrativeEvidenceResolutionStatuses.outOfRange);
      expect(resolution.message, contains('offset'));
    });
  });
}

NarrativeEvidenceRef _buildEvidenceRef({
  required Map<String, Object?> textSpan,
}) {
  return NarrativeEvidenceRef.fromJson(<String, Object?>{
    'evidence_type': NarrativeEvidenceTypes.toolCall,
    'evidence_id': 'evidence-001',
    'text_span': textSpan,
  });
}
