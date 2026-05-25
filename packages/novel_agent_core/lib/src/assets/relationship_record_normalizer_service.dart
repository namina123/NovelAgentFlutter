import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'relationship_record.dart';

class RelationshipRecordNormalizerService {
  const RelationshipRecordNormalizerService();

  RelationshipRecord normalize(JsonMap raw) {
    // 中文注释: 关系资产先固定“主体双方 + 附加关联”最小合同，避免一开始就做成依赖 UI 的重图谱对象。
    return RelationshipRecord(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'],
        ValueReaders.stringValue(raw['title']),
      ).trim(),
      leftEntityId: ValueReaders.stringValue(
        raw['left_entity_id'],
        ValueReaders.stringValue(raw['source_entity_id']),
      ).trim(),
      rightEntityId: ValueReaders.stringValue(
        raw['right_entity_id'],
        ValueReaders.stringValue(raw['target_entity_id']),
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      relationshipType: ValueReaders.stringValue(
        raw['relationship_type'],
        ValueReaders.stringValue(raw['type']),
      ).trim(),
      status: ValueReaders.stringValue(raw['status'], 'active').trim(),
      relatedEntityIds: ValueReaders.stringList(raw['related_entity_ids']),
      relatedForeshadowIds: ValueReaders.stringList(
        raw['related_foreshadow_ids'],
      ),
      relatedTimelineIds: ValueReaders.stringList(raw['related_timeline_ids']),
      tags: ValueReaders.stringList(raw['tags']),
      notes: ValueReaders.stringValue(raw['notes']).trim(),
      sourcePath: ValueReaders.stringValue(
        raw['source_path'],
        ValueReaders.stringValue(raw['relative_path']),
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(RelationshipRecord record) {
    return <String, Object?>{
      'id': record.id,
      'display_name': record.displayName,
      'left_entity_id': record.leftEntityId,
      'right_entity_id': record.rightEntityId,
      'summary': record.summary,
      'relationship_type': record.relationshipType,
      'status': record.status,
      'related_entity_ids': record.relatedEntityIds,
      'related_foreshadow_ids': record.relatedForeshadowIds,
      'related_timeline_ids': record.relatedTimelineIds,
      'tags': record.tags,
      'notes': record.notes,
      'source_path': record.sourcePath,
      'metadata': ValueReaders.deepCopyMap(record.metadata),
    };
  }
}
