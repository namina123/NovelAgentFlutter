import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_relationship_repository.dart';

class ProjectRelationshipStateUpdateService {
  ProjectRelationshipStateUpdateService({
    required ProjectToolHostPort hostPort,
    RelationshipStateUpdateRequestMapperService? requestMapperService,
    RelationshipStateUpdatePlannerService? plannerService,
    ProjectRelationshipRepository? repository,
  }) : _requestMapperService =
           requestMapperService ??
           const RelationshipStateUpdateRequestMapperService(),
       _plannerService =
           plannerService ?? const RelationshipStateUpdatePlannerService(),
       _repository =
           repository ?? ProjectRelationshipRepository(hostPort: hostPort);

  final RelationshipStateUpdateRequestMapperService _requestMapperService;
  final RelationshipStateUpdatePlannerService _plannerService;
  final ProjectRelationshipRepository _repository;

  Future<JsonMap> updateRelationshipState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 关系更新必须带左右实体锚点，避免只写一段描述却无法进入共享关系资产层。
    final request = _requestMapperService.fromToolArguments(arguments);
    if (request.displayName.trim().isEmpty ||
        request.leftEntityId.trim().isEmpty ||
        request.rightEntityId.trim().isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': '关系标题、left_entity_id、right_entity_id 都不能为空。',
      };
    }
    final existing = await _repository.readById(
      project,
      request.id.trim().isEmpty
          ? '${request.leftEntityId}_${request.rightEntityId}'
          : request.id,
    );
    final record = _plannerService.plan(
      request: request,
      existingRecord: existing,
    );
    final path = await _repository.save(project, record);
    return <String, Object?>{
      'ok': true,
      'relationship_id': record.id,
      'relative_path': path,
      'changed_paths': <Object?>[path],
      'summary': '已更新关系：${record.displayName}',
    };
  }
}
