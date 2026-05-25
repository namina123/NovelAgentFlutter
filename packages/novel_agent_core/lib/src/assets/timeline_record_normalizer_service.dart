import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'timeline_record.dart';

class TimelineRecordNormalizerService {
  const TimelineRecordNormalizerService();

  TimelineRecord normalize(JsonMap raw) {
    // 中文注释: 时间线资产保持“事件本体”和“事件关联”分开，后续无论是长任务还是普通项目都能共用同一份事件骨架。
    return TimelineRecord(
      id: ValueReaders.stringValue(raw['id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'],
        ValueReaders.stringValue(raw['title']),
      ).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      eventType: ValueReaders.stringValue(
        raw['event_type'],
        ValueReaders.stringValue(raw['type']),
      ).trim(),
      status: ValueReaders.stringValue(raw['status'], 'planned').trim(),
      phaseLabel: ValueReaders.stringValue(raw['phase_label']).trim(),
      sequence: ValueReaders.intValue(raw['sequence']),
      relatedEntityIds: ValueReaders.stringList(raw['related_entity_ids']),
      relatedForeshadowIds: ValueReaders.stringList(
        raw['related_foreshadow_ids'],
      ),
      relatedRelationshipIds: ValueReaders.stringList(
        raw['related_relationship_ids'],
      ),
      relatedPaths: ValueReaders.stringList(raw['related_paths']),
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

  JsonMap toDocument(TimelineRecord record) {
    return <String, Object?>{
      'id': record.id,
      'display_name': record.displayName,
      'summary': record.summary,
      'event_type': record.eventType,
      'status': record.status,
      'phase_label': record.phaseLabel,
      'sequence': record.sequence,
      'related_entity_ids': record.relatedEntityIds,
      'related_foreshadow_ids': record.relatedForeshadowIds,
      'related_relationship_ids': record.relatedRelationshipIds,
      'related_paths': record.relatedPaths,
      'notes': record.notes,
      'source_path': record.sourcePath,
      'metadata': ValueReaders.deepCopyMap(record.metadata),
    };
  }
}
