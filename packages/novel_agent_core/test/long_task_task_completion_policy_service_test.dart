import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskTaskCompletionPolicyService', () {
    final service = LongTaskTaskCompletionPolicyService(
      modeService: LongTaskModeService(),
    );

    test('sample chapter still waits for user in seed_to_full', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'metadata': <String, Object?>{'stage': 'sample'},
      });

      expect(status, TaskRuntimeConstants.statusWaitingUser);
    });

    test('normal seed_to_full chapter auto completes', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'metadata': <String, Object?>{'stage': 'draft'},
      });

      expect(status, TaskRuntimeConstants.statusSucceeded);
    });

    test('human outline chapter auto completes until explicit checkpoint', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'metadata': <String, Object?>{'stage': 'draft'},
      });

      expect(status, TaskRuntimeConstants.statusSucceeded);
    });

    test('supervised queue still waits after each chapter', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSupervisedChapterQueue,
        'metadata': <String, Object?>{'stage': 'draft'},
      });

      expect(status, TaskRuntimeConstants.statusWaitingUser);
    });

    test('non chapter task still waits for user', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'planning',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'metadata': <String, Object?>{'stage': 'planning'},
      });

      expect(status, TaskRuntimeConstants.statusWaitingUser);
    });

    test(
      'checkpoint followup review auto completes in continuous seed_to_full mode',
      () {
        final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'metadata': <String, Object?>{
            'origin': 'checkpoint_review_suggestion',
            'stage': 'planning',
            'runtime_baseline_id': 'continuous_autonomous',
          },
        });

        expect(status, TaskRuntimeConstants.statusSucceeded);
      },
    );

    test(
      'review repair revision auto completes in continuous seed_to_full mode',
      () {
        final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
          'task_type': 'revision',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'metadata': <String, Object?>{
            'origin': 'review_repair_handoff',
            'stage': 'revision',
            'runtime_baseline_id': 'continuous_autonomous',
          },
        });

        expect(status, TaskRuntimeConstants.statusSucceeded);
      },
    );

    test('chapter gate review task auto completes in autorun baseline', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'review',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      });

      expect(status, TaskRuntimeConstants.statusSucceeded);
    });

    test('chapter gate revision task auto completes in autorun baseline', () {
      final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
        'task_type': 'revision',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
      });

      expect(status, TaskRuntimeConstants.statusSucceeded);
    });

    test(
      'continuous autonomous revision-generated agent task auto completes',
      () {
        final status = service.statusAfterSuccessfulModelStep(<String, Object?>{
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'metadata': <String, Object?>{
            'runtime_baseline_id': 'continuous_autonomous',
            'generated_by': 'LongTaskRevision',
            'stage': 'draft',
          },
        });

        expect(status, TaskRuntimeConstants.statusSucceeded);
      },
    );
  });
}
