import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'relationship_state_update_request.dart';

class RelationshipStateUpdateRequestMapperService {
  const RelationshipStateUpdateRequestMapperService();

  RelationshipStateUpdateRequest fromToolArguments(JsonMap arguments) {
    // 中文注释: 关系工具入口必须先收束左右实体与状态字段，再交给 planner 负责稳定合并。
    return RelationshipStateUpdateRequest(
      id: ValueReaders.stringValue(arguments['relationship_id'] ?? arguments['id']).trim(),
      displayName: ValueReaders.stringValue(
        arguments['display_name'] ?? arguments['title'] ?? arguments['name'],
        '未命名关系',
      ).trim(),
      leftEntityId: ValueReaders.stringValue(
        arguments['left_entity_id'],
      ).trim(),
      rightEntityId: ValueReaders.stringValue(
        arguments['right_entity_id'],
      ).trim(),
      summary: ValueReaders.stringValue(
        arguments['summary'] ?? arguments['content'],
      ).trim(),
      relationshipType: ValueReaders.stringValue(
        arguments['relationship_type'],
      ).trim(),
      status: ValueReaders.stringValue(arguments['status']).trim(),
      relatedForeshadowIds: ValueReaders.stringList(
        arguments['related_foreshadow_ids'],
      ),
      relatedTimelineIds: ValueReaders.stringList(
        arguments['related_timeline_ids'],
      ),
      tags: ValueReaders.stringList(arguments['tags']),
      notes: ValueReaders.stringValue(arguments['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(arguments['metadata'])),
    );
  }
}
