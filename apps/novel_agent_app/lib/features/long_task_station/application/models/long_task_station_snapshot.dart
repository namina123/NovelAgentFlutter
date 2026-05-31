import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

class LongTaskStationSnapshot {
  const LongTaskStationSnapshot({
    required this.runs,
    required this.selectedRunId,
    required this.selectedRunDetail,
    required this.currentProjectPath,
    required this.isCurrentProjectFilterActive,
    required this.detailStatusMessage,
    required this.statusMessage,
    required this.isLoading,
    required this.isDetailLoading,
    required this.isSupervisorRunning,
  });

  final List<RunInstance> runs;
  final String selectedRunId;
  final ProjectLongTaskStationDetail? selectedRunDetail;
  final String currentProjectPath;
  final bool isCurrentProjectFilterActive;
  final String detailStatusMessage;
  final String statusMessage;
  final bool isLoading;
  final bool isDetailLoading;
  final bool isSupervisorRunning;

  bool get hasCurrentProjectScope => currentProjectPath.trim().isNotEmpty;

  List<RunInstance> get visibleRuns {
    if (!isCurrentProjectFilterActive || !hasCurrentProjectScope) {
      return runs;
    }
    final targetPath = currentProjectPath.trim();
    return runs
        .where((run) => run.project.rootPath.trim() == targetPath)
        .toList(growable: false);
  }

  RunInstance? get selectedRun {
    final targetId = selectedRunId.trim();
    if (targetId.isEmpty) {
      return null;
    }
    for (final run in visibleRuns) {
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
      selectedRunDetail: null,
      currentProjectPath: '',
      isCurrentProjectFilterActive: false,
      detailStatusMessage: '请选择一个运行实例查看详情。',
      statusMessage: '等待加载全局长任务运行实例。',
      isLoading: false,
      isDetailLoading: false,
      isSupervisorRunning: false,
    );
  }

  LongTaskStationSnapshot copyWith({
    List<RunInstance>? runs,
    String? selectedRunId,
    ProjectLongTaskStationDetail? selectedRunDetail,
    String? currentProjectPath,
    bool? isCurrentProjectFilterActive,
    bool clearSelectedRunDetail = false,
    String? detailStatusMessage,
    String? statusMessage,
    bool? isLoading,
    bool? isDetailLoading,
    bool? isSupervisorRunning,
  }) {
    return LongTaskStationSnapshot(
      runs: runs ?? this.runs,
      selectedRunId: selectedRunId ?? this.selectedRunId,
      selectedRunDetail: clearSelectedRunDetail
          ? null
          : (selectedRunDetail ?? this.selectedRunDetail),
      currentProjectPath: currentProjectPath ?? this.currentProjectPath,
      isCurrentProjectFilterActive:
          isCurrentProjectFilterActive ?? this.isCurrentProjectFilterActive,
      detailStatusMessage: detailStatusMessage ?? this.detailStatusMessage,
      statusMessage: statusMessage ?? this.statusMessage,
      isLoading: isLoading ?? this.isLoading,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isSupervisorRunning: isSupervisorRunning ?? this.isSupervisorRunning,
    );
  }
}
