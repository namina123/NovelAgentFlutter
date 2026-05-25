import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'foreshadow_record.dart';

class ForeshadowRecordNormalizerService {
  const ForeshadowRecordNormalizerService();

  ForeshadowRecord normalize(JsonMap raw) {
    // 中文注释: 伏笔资产统一抽象成独立对象，后续时间线、提醒和章节回填才能稳定复用。
    return ForeshadowRecord(
      id: ValueReaders.stringValue(raw['id']).trim(),
      title: ValueReaders.stringValue(raw['title']).trim(),
      status: ValueReaders.stringValue(raw['status'], 'planted').trim(),
      summary: ValueReaders.stringValue(raw['summary']).trim(),
      plantedChapterPath: ValueReaders.stringValue(
        raw['planted_chapter_path'],
      ).trim(),
      targetPayoffPath: ValueReaders.stringValue(
        raw['target_payoff_path'],
      ).trim(),
      relatedEntityIds: ValueReaders.stringList(raw['related_entity_ids']),
      relatedTimelineIds: ValueReaders.stringList(raw['related_timeline_ids']),
      relatedRelationshipIds: ValueReaders.stringList(
        raw['related_relationship_ids'],
      ),
      relatedPaths: ValueReaders.stringList(raw['related_paths']),
      triggerConditions: ValueReaders.stringList(raw['trigger_conditions']),
      payoffExpectations: ValueReaders.stringList(raw['payoff_expectations']),
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

  JsonMap toDocument(ForeshadowRecord record) {
    return <String, Object?>{
      'id': record.id,
      'title': record.title,
      'status': record.status,
      'summary': record.summary,
      'planted_chapter_path': record.plantedChapterPath,
      'target_payoff_path': record.targetPayoffPath,
      'related_entity_ids': record.relatedEntityIds,
      'related_timeline_ids': record.relatedTimelineIds,
      'related_relationship_ids': record.relatedRelationshipIds,
      'related_paths': record.relatedPaths,
      'trigger_conditions': record.triggerConditions,
      'payoff_expectations': record.payoffExpectations,
      'tags': record.tags,
      'notes': record.notes,
      'source_path': record.sourcePath,
      'metadata': ValueReaders.deepCopyMap(record.metadata),
    };
  }
}
