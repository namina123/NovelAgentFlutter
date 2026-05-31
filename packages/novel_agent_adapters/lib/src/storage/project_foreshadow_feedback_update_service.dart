import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_foreshadow_repository.dart';

class ProjectForeshadowFeedbackUpdateService {
  ProjectForeshadowFeedbackUpdateService({
    required ProjectToolHostPort hostPort,
    ProjectForeshadowRepository? repository,
    ForeshadowFeedbackSignalExtractorService? signalExtractorService,
    ForeshadowFeedbackPlannerService? plannerService,
  }) : _repository =
           repository ?? ProjectForeshadowRepository(hostPort: hostPort),
       _signalExtractorService =
           signalExtractorService ?? ForeshadowFeedbackSignalExtractorService(),
       _plannerService =
           plannerService ?? const ForeshadowFeedbackPlannerService();

  final ProjectForeshadowRepository _repository;
  final ForeshadowFeedbackSignalExtractorService _signalExtractorService;
  final ForeshadowFeedbackPlannerService _plannerService;

  Future<List<String>> applyReviewReport(
    ProjectDescriptor project,
    JsonMap report,
  ) async {
    // 中文注释: 审稿报告里的伏笔反馈要真正回写资产，而不是只停留在 review JSON。
    final signals = _signalExtractorService.fromReviewReport(report);
    return _applySignals(project, signals);
  }

  Future<List<String>> applyAnalysisDocument(
    ProjectDescriptor project,
    JsonMap document,
  ) async {
    // 中文注释: 章节分析结果如果显式关联了伏笔，也应该通过同一条反馈链回写状态。
    final signals = _signalExtractorService.fromAnalysisDocument(document);
    return _applySignals(project, signals);
  }

  Future<List<String>> _applySignals(
    ProjectDescriptor project,
    List<ForeshadowFeedbackSignal> signals,
  ) async {
    final changedPaths = <String>[];
    final grouped = <String, List<ForeshadowFeedbackSignal>>{};
    for (final signal in signals) {
      grouped.putIfAbsent(signal.foreshadowId, () => <ForeshadowFeedbackSignal>[]).add(signal);
    }
    for (final entry in grouped.entries) {
      final current = await _repository.readById(project, entry.key);
      if (current == null) {
        continue;
      }
      final updated = _plannerService.applySignals(current, entry.value);
      final path = await _repository.save(project, updated);
      if (!changedPaths.contains(path)) {
        changedPaths.add(path);
      }
    }
    return changedPaths;
  }
}
