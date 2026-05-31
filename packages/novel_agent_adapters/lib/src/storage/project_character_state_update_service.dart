import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_character_path_policy.dart';
import 'project_character_profile_repository.dart';
import 'project_character_runtime_state_repository.dart';

class ProjectCharacterStateUpdateService {
  ProjectCharacterStateUpdateService({
    required ProjectToolHostPort hostPort,
    CharacterStateUpdateRequestMapperService? requestMapperService,
    CharacterStateUpdatePlannerService? plannerService,
    ProjectCharacterPathPolicy? pathPolicy,
    ProjectCharacterProfileRepository? profileRepository,
    ProjectCharacterRuntimeStateRepository? runtimeStateRepository,
  }) : _requestMapperService =
           requestMapperService ??
           const CharacterStateUpdateRequestMapperService(),
       _plannerService =
           plannerService ?? const CharacterStateUpdatePlannerService(),
       _pathPolicy = pathPolicy ?? ProjectCharacterPathPolicy(),
       _profileRepository =
           profileRepository ??
           ProjectCharacterProfileRepository(
             hostPort: hostPort,
             pathPolicy: pathPolicy,
           ),
       _runtimeStateRepository =
           runtimeStateRepository ??
           ProjectCharacterRuntimeStateRepository(
             hostPort: hostPort,
             pathPolicy: pathPolicy,
           );

  final CharacterStateUpdateRequestMapperService _requestMapperService;
  final CharacterStateUpdatePlannerService _plannerService;
  final ProjectCharacterPathPolicy _pathPolicy;
  final ProjectCharacterProfileRepository _profileRepository;
  final ProjectCharacterRuntimeStateRepository _runtimeStateRepository;

  Future<JsonMap> updateCharacterState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 这里是普通项目与长任务共用的唯一角色状态写入入口；工具层和后处理层都不要各写一套。
    final request = _requestMapperService.fromToolArguments(arguments);
    if (request.name.trim().isEmpty) {
      return <String, Object?>{'ok': false, 'error': '角色名不能为空。'};
    }
    final existingProfile = await _profileRepository.readProfile(
      project,
      characterId: request.characterId.trim().isEmpty
          ? request.name.trim()
          : request.characterId.trim(),
      displayName: request.name,
    );
    final plan = _plannerService.plan(
      request: request,
      existingProfile: existingProfile,
    );
    await _profileRepository.saveProfile(project, profile: plan.profile);
    await _runtimeStateRepository.saveLatestState(
      project,
      record: plan.latestState,
    );
    await _runtimeStateRepository.appendHistory(
      project,
      record: plan.latestState,
    );
    final profilePath = _pathPolicy.profilePath(plan.profile.id);
    final latestStatePath = _pathPolicy.latestStatePath(plan.profile.id);
    final historyPath = _pathPolicy.historyPath(plan.profile.id);
    return <String, Object?>{
      'ok': true,
      'character_id': plan.profile.id,
      'display_name': plan.profile.displayName,
      'relative_path': profilePath,
      'profile_path': profilePath,
      'latest_state_path': latestStatePath,
      'history_path': historyPath,
      'changed_paths': <Object?>[profilePath, latestStatePath, historyPath],
      'summary': '已更新角色主档与阶段状态：${plan.profile.displayName}',
    };
  }
}
