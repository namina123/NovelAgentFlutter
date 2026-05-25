import 'package:novel_agent_core/novel_agent_core.dart';

class LongTaskStationSnapshot {
  const LongTaskStationSnapshot({
    required this.runs,
    required this.selectedRunId,
    required this.statusMessage,
    required this.isLoading,
    required this.isSupervisorRunning,
  });

  final List<RunInstance> runs;
  final String selectedRunId;
  final String statusMessage;
  final bool isLoading;
  final bool isSupervisorRunning;

  RunInstance? get selectedRun {
    final targetId = selectedRunId.trim();
    if (targetId.isEmpty) {
      return null;
    }
    for (final run in runs) {
      if (run.id == targetId) {
        return run;
      }
    }
    return null;
  }

  factory LongTaskStationSnapshot.initial() {
    return const LongTaskStationSnapshot(
      runs: <RunInstance>[],
      selectedRunId: '',
      statusMessage: '等待加载全局长任务运行实例。',
      isLoading: false,
      isSupervisorRunning: false,
    );
  }

  LongTaskStationSnapshot copyWith({
    List<RunInstance>? runs,
    String? selectedRunId,
    String? statusMessage,
    bool? isLoading,
    bool? isSupervisorRunning,
  }) {
    return LongTaskStationSnapshot(
      runs: runs ?? this.runs,
      selectedRunId: selectedRunId ?? this.selectedRunId,
      statusMessage: statusMessage ?? this.statusMessage,
      isLoading: isLoading ?? this.isLoading,
      isSupervisorRunning: isSupervisorRunning ?? this.isSupervisorRunning,
    );
  }
}
