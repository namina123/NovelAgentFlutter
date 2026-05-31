import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentGroupMemberRoleService {
  const AgentGroupMemberRoleService();

  String resolvePrimaryAgentId(
    JsonMap groupDocument,
    List<String> memberAgentIds,
  ) {
    // 中文注释: primary 允许来自顶层字段、metadata 或默认首成员，保证旧格式组也能稳定升级成 group-first 运行对象。
    if (memberAgentIds.isEmpty) {
      return '';
    }
    final explicitPrimaryId = ValueReaders.stringValue(
      groupDocument['primary_agent_id'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(groupDocument['metadata'])['primary_agent_id'],
      ),
    ).trim();
    if (explicitPrimaryId.isNotEmpty &&
        memberAgentIds.contains(explicitPrimaryId)) {
      return explicitPrimaryId;
    }
    return memberAgentIds.first;
  }

  bool isRequiredMember(
    JsonMap groupDocument,
    String agentId, {
    required String primaryAgentId,
  }) {
    // 中文注释: required/optional 语义优先尊重显式声明；若未声明，则默认除可选成员外全部 required，且 primary 永远 required。
    final cleanAgentId = agentId.trim();
    if (cleanAgentId.isEmpty) {
      return false;
    }
    if (cleanAgentId == primaryAgentId.trim()) {
      return true;
    }
    final requiredIds = _readScopedIds(groupDocument, 'required_agent_ids');
    if (requiredIds.isNotEmpty) {
      return requiredIds.contains(cleanAgentId);
    }
    final optionalIds = _readScopedIds(groupDocument, 'optional_agent_ids');
    if (optionalIds.contains(cleanAgentId)) {
      return false;
    }
    final memberRoles = _readMemberRoles(groupDocument);
    final explicitRole = ValueReaders.stringValue(
      memberRoles[cleanAgentId],
    ).trim().toLowerCase();
    if (explicitRole == 'optional') {
      return false;
    }
    return true;
  }

  bool isPrimaryMember(String agentId, {required String primaryAgentId}) {
    // 中文注释: primary 判断单独暴露，避免 builder 或后续 resolver 自己重复比较字符串。
    return agentId.trim().isNotEmpty && agentId.trim() == primaryAgentId.trim();
  }

  List<String> _readScopedIds(JsonMap groupDocument, String key) {
    final metadata = ValueReaders.mapValue(groupDocument['metadata']);
    return ValueReaders.stringList(groupDocument[key]).isNotEmpty
        ? ValueReaders.stringList(groupDocument[key])
        : ValueReaders.stringList(metadata[key]);
  }

  JsonMap _readMemberRoles(JsonMap groupDocument) {
    final metadata = ValueReaders.mapValue(groupDocument['metadata']);
    final topLevelRoles = ValueReaders.mapValue(groupDocument['member_roles']);
    if (topLevelRoles.isNotEmpty) {
      return topLevelRoles;
    }
    return ValueReaders.mapValue(metadata['member_roles']);
  }
}
