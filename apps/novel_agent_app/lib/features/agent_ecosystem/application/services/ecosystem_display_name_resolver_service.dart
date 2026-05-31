import 'package:novel_agent_core/novel_agent_core.dart';

class AgentDisplayNameResolverService {
  const AgentDisplayNameResolverService();

  String resolve(JsonMap agent) {
    final alias = ValueReaders.stringValue(
      agent['display_name'],
      ValueReaders.stringValue(agent['displayLabel']),
    ).trim();
    if (alias.isNotEmpty) {
      return alias;
    }
    final name = ValueReaders.stringValue(
      agent['name'],
      ValueReaders.stringValue(agent['id']),
    ).trim();
    return name;
  }

  String resolveIdFallback(String agentId) {
    return agentId.trim();
  }
}

class SkillDisplayNameResolverService {
  const SkillDisplayNameResolverService();

  String resolveSkill(JsonMap skill) => _resolveLabel(skill);

  String resolveGroup(JsonMap group) => _resolveLabel(group);

  String resolveIdFallback(String itemId) {
    return itemId.trim();
  }

  String _resolveLabel(JsonMap item) {
    final alias = ValueReaders.stringValue(
      item['display_name'],
      ValueReaders.stringValue(item['displayLabel']),
    ).trim();
    if (alias.isNotEmpty) {
      return alias;
    }
    final name = ValueReaders.stringValue(
      item['name'],
      ValueReaders.stringValue(item['id']),
    ).trim();
    return name;
  }
}
