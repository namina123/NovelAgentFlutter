import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskSampleReadinessService', () {
    const service = LongTaskSampleReadinessService();

    test('builds readiness metadata for information style and outline gate', () {
      final metadata = service.readinessMetadata();

      expect(
        ValueReaders.boolValue(
          metadata[LongTaskSampleReadinessService.readinessCheckpointFlag],
        ),
        isTrue,
      );
      expect(
        ValueReaders.stringList(
          metadata[LongTaskSampleReadinessService.requiredArtifactPathsField],
        ),
        containsAll(<String>[
          'specs/project_spec.md',
          'assets/styles/全书风格指南.md',
          'outlines/story/总纲.md',
          'outlines/chapters/章节任务清单.md',
        ]),
      );
      expect(
        ValueReaders.stringList(
          metadata[LongTaskSampleReadinessService.optionalArtifactPathsField],
        ),
        contains('outlines/volumes'),
      );
    });

    test('sample task requires succeeded readiness checkpoint', () {
      final sampleTask = <String, Object?>{
        'id': 'sample_001',
        'task_type': 'chapter',
        'depends_on': const <Object?>['checkpoint_outline'],
        'metadata': const <String, Object?>{'stage': 'sample'},
      };
      final tasks = <JsonMap>[
        <String, Object?>{
          'id': 'checkpoint_outline',
          'task_type': 'checkpoint',
          'status': TaskRuntimeConstants.statusSucceeded,
          'metadata': service.readinessMetadata(),
        },
      ];

      expect(service.hasSatisfiedReadinessCheckpoint(sampleTask, tasks), isTrue);
    });

    test('sample task without readiness dependency stays blocked', () {
      final sampleTask = <String, Object?>{
        'id': 'sample_legacy',
        'task_type': 'chapter',
        'depends_on': const <Object?>[],
        'metadata': const <String, Object?>{'stage': 'sample'},
      };

      expect(
        service.hasSatisfiedReadinessCheckpoint(sampleTask, const <JsonMap>[]),
        isFalse,
      );
    });
  });
}
