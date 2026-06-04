import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative contract validators', () {
    test('claim validator reports bad refs and evidence structure', () {
      const validator = NarrativeClaimValidator();
      final codes = validator.validateJson(<String, Object?>{
        'claim_id': 'claim-structure-001',
        'claim_namespace': 'project.state',
        'claim_payload': <String, Object?>{'state': 'changed'},
        'affected_refs': <Object?>[
          <String, Object?>{'ref_type': '', 'ref_id': 'chapter-001'},
        ],
        'context_refs': <Object?>[
          <String, Object?>{
            'ref_type': NarrativeRefTypes.segment,
            'ref_id': '',
          },
        ],
        'evidence_refs': <Object?>[
          <String, Object?>{'evidence_type': '', 'evidence_id': ''},
        ],
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.writer},
      });

      expect(
        codes,
        containsAll(<String>[
          NarrativeStateClaimValidationCodes.invalidAffectedRef,
          NarrativeStateClaimValidationCodes.invalidContextRef,
          NarrativeStateClaimValidationCodes.invalidEvidenceRef,
        ]),
      );
    });

    test('profile proposal validator requires minimal patch content', () {
      const validator = NarrativeProfileProposalValidator();
      final emptyPatchCodes = validator.validateJson(<String, Object?>{
        'proposal_id': 'proposal-structure-001',
        'proposal_status': 'proposed',
        'profile_patch': <String, Object?>{
          'patch_id': 'patch-empty-001',
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
        },
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.system},
      });
      final validCodes = validator.validateJson(<String, Object?>{
        'proposal_id': 'proposal-structure-002',
        'proposal_status': 'proposed',
        'profile_patch': <String, Object?>{
          'patch_id': 'patch-non-empty-001',
          'patch_payload': <String, Object?>{'scope_policy': 'scoped'},
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.system,
          },
        },
        'source': <String, Object?>{'source_type': NarrativeSourceTypes.system},
      });

      expect(
        emptyPatchCodes,
        contains(NarrativeProfileValidationCodes.missingPatchContent),
      );
      expect(validCodes, isEmpty);
    });

    test(
      'submission validator accepts no segments and unknown transition kind',
      () {
        const validator = ChapterNarrativeSubmissionValidator();
        final noSegmentCodes = validator.validateJson(<String, Object?>{
          'submission_id': 'submission-validator-001',
          'chapter_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-100',
          },
        });
        final multiSegmentCodes = validator.validateJson(<String, Object?>{
          'submission_id': 'submission-validator-002',
          'chapter_ref': <String, Object?>{
            'ref_type': NarrativeRefTypes.chapter,
            'ref_id': 'chapter-101',
          },
          'segments': <Object?>[
            <String, Object?>{'segment_id': 'segment-001', 'order_index': 0},
            <String, Object?>{'segment_id': 'segment-002', 'order_index': 1},
          ],
          'transitions': <Object?>[
            <String, Object?>{
              'transition_id': 'transition-001',
              'transition_kind': 'future.unknown_transition_kind',
              'from_segment_id': 'segment-001',
              'to_segment_id': 'segment-002',
            },
          ],
        });

        expect(noSegmentCodes, isEmpty);
        expect(multiSegmentCodes, isEmpty);
      },
    );

    test(
      'submission validator reports invalid chapter ref segment order and missing transition segment target',
      () {
        const validator = ChapterNarrativeSubmissionValidator();
        final codes = validator.validateJson(<String, Object?>{
          'submission_id': 'submission-validator-003',
          'chapter_ref': <String, Object?>{
            'ref_type': '',
            'ref_id': 'chapter-102',
          },
          'segments': <Object?>[
            <String, Object?>{'segment_id': 'segment-002', 'order_index': 2},
            <String, Object?>{'segment_id': 'segment-002', 'order_index': 1},
          ],
          'transitions': <Object?>[
            <String, Object?>{
              'transition_id': 'transition-002',
              'transition_kind': 'scope_shift',
              'from_segment_id': 'segment-unknown',
              'to_segment_id': 'segment-002',
            },
          ],
        });

        expect(
          codes,
          containsAll(<String>[
            ChapterNarrativeSubmissionValidationCodes.invalidChapterRef,
            ChapterNarrativeSubmissionValidationCodes.duplicateSegmentId,
            ChapterNarrativeSubmissionValidationCodes.segmentOrderOutOfSequence,
            ChapterNarrativeSubmissionValidationCodes
                .transitionReferencesUnknownSegment,
          ]),
        );
      },
    );
  });
}
