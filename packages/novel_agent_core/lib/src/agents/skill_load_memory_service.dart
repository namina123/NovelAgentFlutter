import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'skill_load_memory.dart';

class SkillLoadMemoryService {
  const SkillLoadMemoryService();

  bool isDuplicateCall(JsonMap call, SkillLoadMemory memory) {
    // 中文注释: 重复判断只处理 load_agent_skill，本服务不接管其他工具的幂等逻辑。
    final toolName = ValueReaders.stringValue(call['name']).trim();
    if (toolName != 'load_agent_skill') {
      return false;
    }
    final arguments = ValueReaders.mapValue(call['arguments']);
    final skillId = ValueReaders.stringValue(arguments['skill_id']).trim();
    if (skillId.isEmpty) {
      return false;
    }
    final referencePath = normalizeReferencePath(arguments['reference_path']);
    if (referencePath.isNotEmpty) {
      return memory.hasReference(skillId, referencePath);
    }
    final detailLevel = normalizeDetailLevel(arguments);
    if (detailLevel == 'full') {
      return memory.hasFull(skillId);
    }
    return memory.hasSummary(skillId);
  }

  JsonMap duplicateResult(JsonMap call, SkillLoadMemory memory) {
    // 中文注释: 重复读取不报错，而是明确告诉上层“这份技能已在本任务记忆里”。
    final arguments = ValueReaders.mapValue(call['arguments']);
    final skillId = ValueReaders.stringValue(arguments['skill_id']).trim();
    final referencePath = normalizeReferencePath(arguments['reference_path']);
    final detailLevel = referencePath.isNotEmpty
        ? 'reference'
        : normalizeDetailLevel(arguments);
    return <String, Object?>{
      'ok': true,
      'not_executed': true,
      'already_loaded': true,
      'skill_id': skillId,
      'detail_level': detailLevel,
      if (referencePath.isNotEmpty) 'reference_path': referencePath,
      'error': referencePath.isNotEmpty
          ? '本任务已读取该技能 reference，无需重复加载。'
          : '本任务已读取该技能说明，无需重复加载。',
      'changed_paths': const <Object?>[],
      'loaded_detail_level': memory.detailLevelForSkill(skillId),
      'loaded_reference_paths': memory.loadedReferencesForSkill(skillId),
    };
  }

  void recordCallResult(
    JsonMap call,
    JsonMap result,
    SkillLoadMemory memory,
  ) {
    // 中文注释: 只有成功的技能读取才进入记忆，失败或未命中不污染后续判定。
    if (!ValueReaders.boolValue(result['ok'], true)) {
      return;
    }
    final arguments = ValueReaders.mapValue(call['arguments']);
    final skillId = ValueReaders.stringValue(
      result['skill_id'],
      ValueReaders.stringValue(arguments['skill_id']),
    ).trim();
    if (skillId.isEmpty) {
      return;
    }
    final referencePath = normalizeReferencePath(
      result['reference_path'].toString().isNotEmpty
          ? result['reference_path']
          : arguments['reference_path'],
    );
    if (referencePath.isNotEmpty) {
      memory.markReference(skillId, referencePath);
      return;
    }
    final detailLevel = ValueReaders.stringValue(
      result['detail_level'],
      normalizeDetailLevel(arguments),
    ).trim().toLowerCase();
    if (detailLevel == 'full') {
      memory.markFull(skillId);
      return;
    }
    memory.markSummary(skillId);
  }

  String normalizeDetailLevel(JsonMap arguments) {
    // 中文注释: detail_level 缺失时统一回退到 summary，保持工具默认语义稳定。
    final detailLevel = ValueReaders.stringValue(
      arguments['detail_level'],
      'summary',
    ).trim().toLowerCase();
    if (detailLevel == 'full') {
      return 'full';
    }
    return 'summary';
  }

  String normalizeReferencePath(Object? rawValue) {
    final value = ValueReaders.stringValue(rawValue).trim();
    if (value.isEmpty) {
      return '';
    }
    return value.replaceAll('\\', '/');
  }
}
