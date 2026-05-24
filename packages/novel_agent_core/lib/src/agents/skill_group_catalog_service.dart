import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'skill_group_normalizer_service.dart';

class SkillGroupCatalogService {
  SkillGroupCatalogService({SkillGroupNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? SkillGroupNormalizerService();

  final SkillGroupNormalizerService _normalizerService;

  List<JsonMap> groupsFromJson(String rawJson) {
    // 中文注释: 技能组目录和智能体组一样只消费纯文本 JSON，保持 core 不接触宿主文件系统。
    final decoded = _jsonDecodeSafe(rawJson);
    final root = ValueReaders.mapValue(decoded);
    final rawGroups = ValueReaders.objectList(
      root['groups'] ?? root['skill_groups'],
    );
    final result = <JsonMap>[];
    for (final rawGroup in rawGroups) {
      final normalized = _normalizerService.normalizeSkillGroup(
        ValueReaders.mapValue(rawGroup),
      );
      if (ValueReaders.stringValue(normalized['id']).trim().isNotEmpty) {
        result.add(normalized);
      }
    }
    return result;
  }

  Object? _jsonDecodeSafe(String rawJson) {
    try {
      return jsonDecode(rawJson);
    } catch (_) {
      return null;
    }
  }
}
