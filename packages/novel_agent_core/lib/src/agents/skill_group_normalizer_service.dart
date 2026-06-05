import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_id_service.dart';
import 'agent_string_list_service.dart';

class SkillGroupNormalizerService {
  SkillGroupNormalizerService({
    AgentIdService? idService,
    AgentStringListService? stringListService,
  }) : _idService = idService ?? AgentIdService(),
       _stringListService = stringListService ?? AgentStringListService();

  final AgentIdService _idService;
  final AgentStringListService _stringListService;

  JsonMap normalizeSkillGroup(JsonMap group) {
    // 中文注释: 技能组只负责声明技能集合与用途说明，不把工具权限和运行策略混进这个结构。
    final id = _idService.safeAgentId(
      ValueReaders.stringValue(group['id']).trim(),
    );
    return <String, Object?>{
      ...group,
      'schema_version': ValueReaders.intValue(group['schema_version'], 1),
      'id': id,
      'version': ValueReaders.stringValue(group['version'], '1').trim(),
      'name': ValueReaders.stringValue(
        group['name'],
        id.isEmpty ? '未命名技能组' : id,
      ).trim(),
      'description': ValueReaders.stringValue(group['description']).trim(),
      'source': ValueReaders.stringValue(group['source'], 'user'),
      'skills': _stringListService.normalize(group['skills']),
      'metadata': ValueReaders.mapValue(group['metadata']),
      'updated_at': ValueReaders.stringValue(group['updated_at']),
    };
  }
}
