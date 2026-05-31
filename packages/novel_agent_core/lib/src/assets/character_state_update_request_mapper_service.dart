import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'character_state_update_request.dart';

class CharacterStateUpdateRequestMapperService {
  const CharacterStateUpdateRequestMapperService();

  CharacterStateUpdateRequest fromToolArguments(JsonMap arguments) {
    // 中文注释: 工具参数到领域请求的映射集中在 core，避免 GUI/CLI 各自散写字段兼容。
    return CharacterStateUpdateRequest(
      name: ValueReaders.stringValue(
        arguments['name'] ?? arguments['display_name'],
        '未命名角色',
      ).trim(),
      characterId: ValueReaders.stringValue(
        arguments['character_id'] ?? arguments['id'],
      ).trim(),
      status: ValueReaders.stringValue(arguments['status']).trim(),
      role: ValueReaders.stringValue(arguments['role']).trim(),
      content: ValueReaders.stringValue(arguments['content']).trim(),
      stageId: ValueReaders.stringValue(arguments['stage_id']).trim(),
      stageLabel: ValueReaders.stringValue(arguments['stage_label']).trim(),
      sourcePaths: ValueReaders.stringList(arguments['source_paths']),
      relatedTimelineIds: ValueReaders.stringList(
        arguments['related_timeline_ids'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['metadata']),
      ),
    );
  }
}
