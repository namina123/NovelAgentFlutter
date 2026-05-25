import '../packages/frontmatter_yaml_writer_service.dart';
import 'relationship_record.dart';
import 'relationship_record_normalizer_service.dart';

class RelationshipRecordMarkdownCodecService {
  RelationshipRecordMarkdownCodecService({
    RelationshipRecordNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const RelationshipRecordNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final RelationshipRecordNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(RelationshipRecord record) {
    // 中文注释: 关系资产也落成普通 Markdown 文件，后续不论选 Markdown 项目还是 SQLite 项目都能投影成同一可读格式。
    final document = _normalizerService.toDocument(record);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'display_name': document['display_name'],
      'left_entity_id': document['left_entity_id'],
      'right_entity_id': document['right_entity_id'],
      'relationship_type': document['relationship_type'],
      'status': document['status'],
      'related_entity_ids': document['related_entity_ids'],
      'related_foreshadow_ids': document['related_foreshadow_ids'],
      'related_timeline_ids': document['related_timeline_ids'],
      'tags': document['tags'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final summary = record.summary.trim().isEmpty
        ? '请补充关系摘要。'
        : record.summary.trim();
    final notes = record.notes.trim();
    final notesBlock = notes.isEmpty ? '' : '\n## 备注\n\n$notes\n';
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n# ${record.displayName}\n\n$summary$notesBlock';
  }
}
