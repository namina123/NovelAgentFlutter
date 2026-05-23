import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_id_service.dart';
import 'agent_orchestration_service.dart';
import 'agent_string_list_service.dart';

class AgentGroupNormalizerService {
  AgentGroupNormalizerService({
    AgentIdService? idService,
    AgentOrchestrationService? orchestrationService,
    AgentStringListService? stringListService,
  }) : _idService = idService ?? AgentIdService(),
       _orchestrationService =
           orchestrationService ?? AgentOrchestrationService(),
       _stringListService = stringListService ?? AgentStringListService();

  final AgentIdService _idService;
  final AgentOrchestrationService _orchestrationService;
  final AgentStringListService _stringListService;

  JsonMap normalizeAgentGroup(JsonMap group) {
    // 中文注释: 智能体组只描述编排素材，不负责运行，因此这里只收敛声明字段。
    final id = _idService.safeAgentId(
      ValueReaders.stringValue(group['id']).trim(),
    );
    return <String, Object?>{
      ...group,
      'schema_version': ValueReaders.intValue(group['schema_version'], 1),
      'id': id,
      'name': ValueReaders.stringValue(
        group['name'],
        id.isEmpty ? '未命名智能体组' : id,
      ).trim(),
      'description': ValueReaders.stringValue(group['description']).trim(),
      'source': ValueReaders.stringValue(group['source'], 'builtin'),
      'enabled': ValueReaders.boolValue(group['enabled']),
      'orchestration': _orchestrationService.normalizeOrchestration(
        ValueReaders.stringValue(group['orchestration'], 'supervised'),
      ),
      'agents': _stringListService.normalize(group['agents']),
      'metadata': ValueReaders.mapValue(group['metadata']),
      'updated_at': ValueReaders.stringValue(group['updated_at']),
    };
  }
}
