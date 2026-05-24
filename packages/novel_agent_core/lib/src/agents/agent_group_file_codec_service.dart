import 'dart:convert';

import '../common/json_types.dart';
import 'agent_group_normalizer_service.dart';

class AgentGroupFileCodecService {
  AgentGroupFileCodecService({AgentGroupNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? AgentGroupNormalizerService();

  final AgentGroupNormalizerService _normalizerService;

  String encodeAgentGroup(JsonMap group) {
    // 中文注释: 智能体组文件编码与 normalizer 分开，避免保存入口散落各处自己拼 JSON。
    final normalized = _normalizerService.normalizeAgentGroup(group);
    return const JsonEncoder.withIndent('  ').convert(normalized);
  }
}
