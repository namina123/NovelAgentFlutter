import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterNarrativeSubmission contracts', () {
    test('supports multiple in-chapter transitions and empty claims', () {
      const codec = ChapterNarrativeSubmissionCodecService();
      final submission = codec.fromJson(<String, Object?>{
        'submission_id': 'submission-001',
        'chapter_ref': <String, Object?>{
          'ref_type': NarrativeRefTypes.chapter,
          'ref_id': 'chapter-001',
          'relative_path': 'chapters/第01章.md',
        },
        'title': '第01章',
        'summary': '本章有多个连续性转折。',
        'claims': const <Object?>[],
        'segments': <Object?>[
          <String, Object?>{
            'segment_id': 'segment-001',
            'order_index': 0,
            'segment_label': '开场',
            'summary': '主角在旧场景中行动。',
            'constraint_coverage': <String, Object?>{
              'length_policy': 'within_window',
            },
          },
          <String, Object?>{
            'segment_id': 'segment-002',
            'order_index': 1,
            'segment_label': '转场',
            'summary': '视角和作用域切换。',
          },
          <String, Object?>{
            'segment_id': 'segment-003',
            'order_index': 2,
            'segment_label': '收束',
            'summary': '落到新的末状态。',
          },
        ],
        'transitions': <Object?>[
          <String, Object?>{
            'transition_id': 'transition-001',
            'transition_kind': 'scope_shift',
            'from_segment_id': 'segment-001',
            'to_segment_id': 'segment-002',
            'summary': '从旧作用域切到新作用域。',
          },
          <String, Object?>{
            'transition_id': 'transition-002',
            'transition_kind': 'state_commit',
            'from_segment_id': 'segment-002',
            'to_segment_id': 'segment-003',
            'summary': '新的章末状态提交。',
          },
        ],
        'final_state_summary': <String, Object?>{
          'active_scope': 'scope:new',
          'active_frame': 'frame:002',
        },
        'constraint_coverage': <String, Object?>{
          'expression_constraints': <Object?>['no_ai_tone'],
        },
      });

      expect(submission.claims, isEmpty);
      expect(submission.segments, hasLength(3));
      expect(submission.transitions, hasLength(2));
      expect(submission.transitions.first.fromSegmentId, 'segment-001');
      expect(submission.transitions.last.toSegmentId, 'segment-003');
      expect(
        (submission.finalStateSummary['active_scope'] as String),
        'scope:new',
      );
      expect(submission.validateBasics(), isEmpty);
    });

    test('preserves unknown transition kind and span refs during round-trip', () {
      const codec = ChapterNarrativeSubmissionCodecService();
      final submission = codec.fromJson(<String, Object?>{
        'submission_id': 'submission-002',
        'chapter_ref': <String, Object?>{
          'ref_type': NarrativeRefTypes.chapter,
          'ref_id': 'chapter-002',
        },
        'segments': <Object?>[
          <String, Object?>{
            'segment_id': 'segment-010',
            'order_index': 10,
            'text_span': <String, Object?>{
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapter-002',
              },
              'start_offset': 100,
              'end_offset': 200,
            },
            'scope_ref': <String, Object?>{
              'ref_type': 'scope',
              'ref_id': 'scope:night',
            },
            'frame_ref': <String, Object?>{
              'ref_type': 'frame',
              'ref_id': 'frame:night-01',
            },
            'claim_ids': <Object?>['claim-001'],
          },
        ],
        'transitions': <Object?>[
          <String, Object?>{
            'transition_id': 'transition-unknown',
            'transition_kind': 'future.unknown_transition_kind',
            'from_segment_id': 'segment-010',
            'to_segment_id': 'segment-010',
            'text_span': <String, Object?>{
              'target_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapter-002',
              },
              'start_offset': 150,
              'end_offset': 180,
            },
          },
        ],
      });

      final encoded = codec.toJson(submission);

      expect(
        submission.transitions.single.transitionKind,
        'future.unknown_transition_kind',
      );
      expect(submission.segments.single.scopeRef!.refType, 'scope');
      expect(submission.segments.single.frameRef!.refType, 'frame');
      expect(
        ((encoded['transitions'] as List<Object?>).single
            as Map<String, Object?>)['transition_kind'],
        'future.unknown_transition_kind',
      );
    });

    test('validation basics report missing submission chapter and transition ids', () {
      final submission = ChapterNarrativeSubmission.fromJson(<String, Object?>{
        'submission_id': '',
        'chapter_ref': <String, Object?>{},
        'segments': <Object?>[
          <String, Object?>{
            'segment_id': '',
          },
        ],
        'transitions': <Object?>[
          <String, Object?>{
            'transition_id': '',
            'transition_kind': '',
          },
        ],
      });

      expect(
        submission.validateBasics(),
        containsAll(<String>[
          ChapterNarrativeSubmissionValidationCodes.missingSubmissionId,
          ChapterNarrativeSubmissionValidationCodes.missingChapterRef,
          ChapterNarrativeSubmissionValidationCodes.missingSegmentId,
          ChapterNarrativeSubmissionValidationCodes.missingTransitionId,
          ChapterNarrativeSubmissionValidationCodes.missingTransitionKind,
        ]),
      );
    });
  });
}
