import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ContinuousTaskLifecycleStopOutcomeResolverService', () {
    const service = ContinuousTaskLifecycleStopOutcomeResolverService();

    test('projects lifecycle metadata into stop outcome', () {
      final outcome = service.resolve(
        const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.recovering,
          stopCategory: ContinuousTaskStopCategories.technicalFailure,
          reason: 'provider_transport_failed',
          metadata: <String, Object?>{'source_file_path': 'references/hp1.txt'},
        ),
        note: 'retry_window_open',
      );

      expect(outcome.present, isTrue);
      expect(outcome.category, LongTaskStopOutcomeCategories.technicalFailure);
      expect(outcome.reason, 'provider_transport_failed');
      expect(outcome.legacyStopReason, 'technical_failure');
      expect(outcome.summary, 'retry_window_open');
      expect(
        ValueReaders.stringValue(outcome.metadata['source_file_path']),
        'references/hp1.txt',
      );
    });
  });
}
