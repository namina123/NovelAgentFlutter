import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_string_list_service.dart';

class AgentMemberDirectoryService {
  AgentMemberDirectoryService({AgentStringListService? stringListService})
    : _stringListService = stringListService ?? AgentStringListService();

  final AgentStringListService _stringListService;

  JsonMap agentsById(List<Object?> availableAgents) {
    // 中文注释: 目录索引统一在这里做，避免不同编排服务各自维护一份 id 查找逻辑。
    final result = <String, Object?>{};
    for (final rawAgent in availableAgents) {
      final agent = ValueReaders.mapValue(rawAgent);
      final agentId = ValueReaders.stringValue(agent['id']).trim();
      if (agentId.isNotEmpty) {
        result[agentId] = ValueReaders.deepCopyMap(agent);
      }
    }
    return result;
  }

  List<JsonMap> agentsInGroup(
    JsonMap agentGroup,
    List<Object?> availableAgents,
  ) {
    // 中文注释: 默认全能智能体只作为主控，不自动进入子智能体候选池。
    final result = <JsonMap>[];
    final byId = agentsById(availableAgents);
    for (final agentId in _stringListService.normalize(agentGroup['agents'])) {
      if (agentId.isEmpty ||
          agentId == 'default_generalist' ||
          !byId.containsKey(agentId)) {
        continue;
      }
      result.add(ValueReaders.mapValue(byId[agentId]));
    }
    return result;
  }

  JsonMap agentById(String agentId, List<Object?> availableAgents) {
    // 中文注释: 这里保留线性查找入口，方便上层直接在候选数组中读取单个智能体。
    for (final rawAgent in availableAgents) {
      final agent = ValueReaders.mapValue(rawAgent);
      if (ValueReaders.stringValue(agent['id']).trim() == agentId.trim()) {
        return ValueReaders.deepCopyMap(agent);
      }
    }
    return <String, Object?>{};
  }
}
