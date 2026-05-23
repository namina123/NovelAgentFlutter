import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_normalizer_service.dart';

class AgentGroupCatalogService {
  AgentGroupCatalogService({AgentGroupNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? AgentGroupNormalizerService();

  final AgentGroupNormalizerService _normalizerService;

  List<JsonMap> builtinGroupsFromJson(String rawJson) {
    // 中文注释: 组配置和原型一样只接收文本输入，保持 core 不碰资源路径和宿主文件系统。
    final decoded = _jsonDecodeSafe(rawJson);
    final root = ValueReaders.mapValue(decoded);
    final rawGroups = ValueReaders.objectList(
      root['groups'] ?? root['agent_groups'],
    );
    final result = <JsonMap>[];
    for (final rawGroup in rawGroups) {
      final normalized = _normalizerService.normalizeAgentGroup(
        ValueReaders.mapValue(rawGroup),
      );
      if (ValueReaders.stringValue(normalized['id']).trim().isNotEmpty) {
        result.add(normalized);
      }
    }
    return result;
  }

  String agentGroupSummaryText(List<Object?> groups) {
    // 中文注释: 这里只渲染轻量摘要，避免把完整编排配置对象塞进提示词或调试页。
    if (groups.isEmpty) {
      return '当前没有可用智能体组。';
    }
    final lines = <String>['内置智能体组摘要：'];
    for (final rawGroup in groups) {
      final group = ValueReaders.mapValue(rawGroup);
      if (group.isEmpty) {
        continue;
      }
      final id = ValueReaders.stringValue(group['id']).trim();
      lines.add(
        '- ${ValueReaders.stringValue(group['name'], id)}（group_id: $id）：'
        '${ValueReaders.stringValue(group['description'])}',
      );
    }
    return lines.join('\n');
  }

  Object? _jsonDecodeSafe(String rawJson) {
    // 中文注释: 解析失败直接回 null，让调用者继续使用更高层的兜底策略。
    try {
      return jsonDecode(rawJson);
    } catch (_) {
      return null;
    }
  }
}
