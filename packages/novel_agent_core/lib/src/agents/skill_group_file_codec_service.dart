import 'dart:convert';

import '../common/json_types.dart';
import 'skill_group_normalizer_service.dart';

class SkillGroupFileCodecService {
  SkillGroupFileCodecService({SkillGroupNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? SkillGroupNormalizerService();

  final SkillGroupNormalizerService _normalizerService;

  String encodeSkillGroup(JsonMap group) {
    // 中文注释: 技能组文件编码单独收口，后续如果从 JSON 迁到 Markdown/嵌合体只改这里。
    final normalized = _normalizerService.normalizeSkillGroup(group);
    return const JsonEncoder.withIndent('  ').convert(normalized);
  }
}
