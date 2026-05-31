import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'foreshadow_state_update_request.dart';

class ForeshadowStateUpdateRequestMapperService {
  const ForeshadowStateUpdateRequestMapperService();

  ForeshadowStateUpdateRequest fromToolArguments(JsonMap arguments) {
    // 中文注释: 伏笔工具参数归一化集中在 core，避免不同宿主再重复兼容 title/name/status 等字段。
    return ForeshadowStateUpdateRequest(
      id: ValueReaders.stringValue(arguments['foreshadow_id'] ?? arguments['id']).trim(),
      title: ValueReaders.stringValue(
        arguments['title'] ?? arguments['name'],
        '未命名伏笔',
      ).trim(),
      status: ValueReaders.stringValue(arguments['status']).trim(),
      summary: ValueReaders.stringValue(
        arguments['summary'] ?? arguments['content'],
      ).trim(),
      plantedChapterPath: ValueReaders.stringValue(
        arguments['planted_chapter_path'],
      ).trim(),
      targetPayoffPath: ValueReaders.stringValue(
        arguments['target_payoff_path'],
      ).trim(),
      relatedEntityIds: ValueReaders.stringList(arguments['related_entity_ids']),
      relatedTimelineIds: ValueReaders.stringList(
        arguments['related_timeline_ids'],
      ),
      relatedRelationshipIds: ValueReaders.stringList(
        arguments['related_relationship_ids'],
      ),
      relatedPaths: ValueReaders.stringList(arguments['related_paths']),
      triggerConditions: ValueReaders.stringList(
        arguments['trigger_conditions'],
      ),
      payoffExpectations: ValueReaders.stringList(
        arguments['payoff_expectations'],
      ),
      tags: ValueReaders.stringList(arguments['tags']),
      notes: ValueReaders.stringValue(arguments['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(arguments['metadata'])),
    );
  }
}
