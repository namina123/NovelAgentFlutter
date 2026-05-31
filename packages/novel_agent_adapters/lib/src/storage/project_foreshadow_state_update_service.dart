import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_foreshadow_repository.dart';

class ProjectForeshadowStateUpdateService {
  ProjectForeshadowStateUpdateService({
    required ProjectToolHostPort hostPort,
    ForeshadowStateUpdateRequestMapperService? requestMapperService,
    ForeshadowStateUpdatePlannerService? plannerService,
    ProjectForeshadowRepository? repository,
  }) : _requestMapperService =
           requestMapperService ??
           const ForeshadowStateUpdateRequestMapperService(),
       _plannerService =
           plannerService ?? const ForeshadowStateUpdatePlannerService(),
       _repository =
           repository ??
           ProjectForeshadowRepository(hostPort: hostPort);

  final ForeshadowStateUpdateRequestMapperService _requestMapperService;
  final ForeshadowStateUpdatePlannerService _plannerService;
  final ProjectForeshadowRepository _repository;

  Future<JsonMap> updateForeshadowState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 伏笔更新入口负责稳定写回主档，不再让模型通过通用写文件随意拼伏笔文档。
    final request = _requestMapperService.fromToolArguments(arguments);
    if (request.title.trim().isEmpty) {
      return <String, Object?>{'ok': false, 'error': '伏笔标题不能为空。'};
    }
    final existing = await _repository.readById(
      project,
      request.id.trim().isEmpty ? request.title : request.id,
    );
    final record = _plannerService.plan(
      request: request,
      existingRecord: existing,
    );
    final path = await _repository.save(project, record);
    return <String, Object?>{
      'ok': true,
      'foreshadow_id': record.id,
      'relative_path': path,
      'changed_paths': <Object?>[path],
      'summary': '已更新伏笔：${record.title}',
    };
  }
}
