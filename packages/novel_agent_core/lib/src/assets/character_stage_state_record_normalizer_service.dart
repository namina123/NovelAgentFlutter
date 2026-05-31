import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'character_stage_state_record.dart';

class CharacterStageStateRecordNormalizerService {
  const CharacterStageStateRecordNormalizerService();

  CharacterStageStateRecord normalize(JsonMap raw) {
    // 中文注释: 阶段状态记录要独立于主档案归一化，保证后续普通项目和长任务都走同一结构。
    return CharacterStageStateRecord(
      id: ValueReaders.stringValue(raw['id']).trim(),
      characterId: ValueReaders.stringValue(raw['character_id']).trim(),
      displayName: ValueReaders.stringValue(
        raw['display_name'] ?? raw['name'],
      ).trim(),
      stageId: ValueReaders.stringValue(raw['stage_id']).trim(),
      stageLabel: ValueReaders.stringValue(raw['stage_label']).trim(),
      status: ValueReaders.stringValue(raw['status']).trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      sourcePaths: ValueReaders.stringList(raw['source_paths']),
      relatedTimelineIds: ValueReaders.stringList(raw['related_timeline_ids']),
      updatedAt: ValueReaders.stringValue(raw['updated_at']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['metadata']),
      ),
    );
  }

  JsonMap toDocument(CharacterStageStateRecord record) {
    return <String, Object?>{
      'id': record.id,
      'character_id': record.characterId,
      'display_name': record.displayName,
      'stage_id': record.stageId,
      'stage_label': record.stageLabel,
      'status': record.status,
      'summary': record.summary,
      'source_paths': ValueReaders.deepCopyList(
        record.sourcePaths.cast<Object?>(),
      ),
      'related_timeline_ids': ValueReaders.deepCopyList(
        record.relatedTimelineIds.cast<Object?>(),
      ),
      'updated_at': record.updatedAt,
      'metadata': ValueReaders.deepCopyMap(record.metadata),
    };
  }
}
