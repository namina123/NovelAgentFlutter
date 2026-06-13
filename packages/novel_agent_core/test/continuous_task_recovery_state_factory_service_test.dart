import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskRecoveryStateFactoryService', () {
    const service = ContinuousTaskRecoveryStateFactoryService();

    test('builds shared resume-ready recovery state from lifecycle truth', () {
      final recoveryState = service.resumeReady(
        lifecycleState: const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.recovering,
          stopCategory: ContinuousTaskStopCategories.technicalFailure,
          reason: 'provider_transport_failed',
          metadata: <String, Object?>{'source_file_path': 'references/hp1.txt'},
        ),
        recommendedAction: 'resume_reference_extraction',
        note: 'reference_extraction_recovering',
        autoRetryEligible: true,
        taskId: 'run_hp1',
        taskTitle: 'Harry Potter',
        metadata: const <String, Object?>{
          'requested_strategy_profile_id': 'reference_extraction.standard',
        },
      );

      expect(recoveryState.present, isTrue);
      expect(recoveryState.state, LongTaskRecoveryStates.resumeReady);
      expect(recoveryState.runStatus, LongTaskRunStatus.recovering.id);
      expect(recoveryState.recommendedAction, 'resume_reference_extraction');
      expect(recoveryState.reason, 'provider_transport_failed');
      expect(recoveryState.note, 'reference_extraction_recovering');
      expect(recoveryState.autoRetryEligible, isTrue);
      expect(
        recoveryState.stopOutcome.category,
        LongTaskStopOutcomeCategories.technicalFailure,
      );
      expect(
        ValueReaders.stringValue(
          recoveryState.stopOutcome.metadata['source_file_path'],
        ),
        'references/hp1.txt',
      );
      expect(
        ValueReaders.stringValue(
          recoveryState.metadata['requested_strategy_profile_id'],
        ),
        'reference_extraction.standard',
      );
    });
  });
}
