import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_timeline_repository.dart';

class ProjectTimelineStateUpdateService {
  ProjectTimelineStateUpdateService({
    required ProjectToolHostPort hostPort,
    TimelineStateUpdateRequestMapperService? requestMapperService,
    TimelineStateUpdatePlannerService? plannerService,
    ProjectTimelineRepository? repository,
  }) : _requestMapperService =
           requestMapperService ?? const TimelineStateUpdateRequestMapperService(),
       _plannerService =
           plannerService ?? const TimelineStateUpdatePlannerService(),
       _repository =
           repository ?? ProjectTimelineRepository(hostPort: hostPort);

  final TimelineStateUpdateRequestMapperService _requestMapperService;
  final TimelineStateUpdatePlannerService _plannerService;
  final ProjectTimelineRepository _repository;

  Future<JsonMap> updateTimelineState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 时间线更新统一写入资产目录，让章节完成后的事件推进有稳定落点。
    final request = _requestMapperService.fromToolArguments(arguments);
    if (request.displayName.trim().isEmpty) {
      return <String, Object?>{'ok': false, 'error': '时间线标题不能为空。'};
    }
    final existing = await _repository.readById(
      project,
      request.id.trim().isEmpty ? request.displayName : request.id,
    );
    final record = _plannerService.plan(
      request: request,
      existingRecord: existing,
    );
    final path = await _repository.save(project, record);
    return <String, Object?>{
      'ok': true,
      'timeline_id': record.id,
      'relative_path': path,
      'changed_paths': <Object?>[path],
      'summary': '已更新时间线：${record.displayName}',
    };
  }
}
