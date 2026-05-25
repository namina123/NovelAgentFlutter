import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_mode_guidance_repository.dart';
import '../storage/project_task_repository.dart';

class ProjectModeGuidanceRevisitService {
  ProjectModeGuidanceRevisitService({
    required ProjectTaskRepository taskRepository,
    required ProjectModeGuidanceRepository repository,
    LongTaskCheckpointGuidanceRevisitService? revisitService,
  }) : _taskRepository = taskRepository,
       _repository = repository,
       _revisitService =
           revisitService ?? LongTaskCheckpointGuidanceRevisitService();

  final ProjectTaskRepository _taskRepository;
  final ProjectModeGuidanceRepository _repository;
  final LongTaskCheckpointGuidanceRevisitService _revisitService;

  Future<JsonMap> buildPackage(
    ProjectDescriptor project,
    String checkpointReviewPath,
  ) async {
    // 中文注释: adapter 层负责从项目态恢复 mode guidance，并补文件预览给 GUI/CLI 使用。
    final checkpointReview = await _taskRepository.loadRecord(
      project,
      checkpointReviewPath,
    );
    if (checkpointReview.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Checkpoint review not found.',
      };
    }
    final modeId = _modeIdFrom(checkpointReview);
    if (modeId.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error':
            'Mode guidance is not available for current checkpoint review.',
      };
    }
    final state = await _repository.load(project, modeId: modeId);
    if (state == null) {
      return <String, Object?>{
        'ok': false,
        'error': 'Mode guidance state not found.',
        'mode_id': modeId,
      };
    }
    final base = _revisitService.buildPackage(
      checkpointReview: checkpointReview,
      state: state,
    );
    final items = <JsonMap>[];
    for (final item in ValueReaders.mapList(base['items'])) {
      final path = ValueReaders.stringValue(item['path']).trim();
      final preview = path.isEmpty
          ? ''
          : _previewText(
              await _taskRepository.readTextFile(project, path) ?? '',
            );
      items.add(<String, Object?>{...item, 'content_preview': preview});
    }
    return <String, Object?>{
      ...base,
      'checkpoint_review_path': checkpointReviewPath,
      'items': items,
    };
  }

  String _modeIdFrom(JsonMap checkpointReview) {
    for (final path in ValueReaders.stringList(
      checkpointReview['persistent_context_paths'],
    )) {
      final match = RegExp(
        r'tracking/modes/([^/]+)/guidance\.md',
      ).firstMatch(path);
      if (match != null) {
        final candidate = match.group(1)?.trim() ?? '';
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }
    final modeId = ValueReaders.stringValue(checkpointReview['mode']).trim();
    if (modeId == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 'seed_autopilot_novel';
    }
    if (modeId == TaskRuntimeConstants.modeHumanOutlineAiDraft) {
      return 'full_outline_consensus';
    }
    return modeId;
  }

  String _previewText(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 180) {
      return clean;
    }
    return '${clean.substring(0, 180)}...';
  }
}
