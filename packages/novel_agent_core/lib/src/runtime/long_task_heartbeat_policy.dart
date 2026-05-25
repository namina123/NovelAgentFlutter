import 'run_instance.dart';
import 'runtime_baseline.dart';

abstract class LongTaskHeartbeatPolicy {
  Duration heartbeatIntervalFor(RunInstance instance, RuntimeBaseline baseline);

  Duration staleAfterFor(RunInstance instance, RuntimeBaseline baseline);

  DateTime? nextHeartbeatAt(RunInstance instance, RuntimeBaseline baseline);

  bool isHeartbeatDue(
    RunInstance instance,
    RuntimeBaseline baseline, {
    DateTime? now,
  });

  bool isStale(RunInstance instance, RuntimeBaseline baseline, {DateTime? now});
}
