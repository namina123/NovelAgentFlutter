import '../packages/frontmatter_yaml_writer_service.dart';
import 'timeline_record.dart';
import 'timeline_record_normalizer_service.dart';

class TimelineRecordMarkdownCodecService {
  TimelineRecordMarkdownCodecService({
    TimelineRecordNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const TimelineRecordNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final TimelineRecordNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(TimelineRecord record) {
    // 中文注释: 时间线资产统一落成 Markdown，后续普通项目和长任务都能用同一文件形态浏览与编辑。
    final document = _normalizerService.toDocument(record);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'display_name': document['display_name'],
      'event_type': document['event_type'],
      'status': document['status'],
      'phase_label': document['phase_label'],
      'sequence': document['sequence'],
      'related_entity_ids': document['related_entity_ids'],
      'related_foreshadow_ids': document['related_foreshadow_ids'],
      'related_relationship_ids': document['related_relationship_ids'],
      'related_paths': document['related_paths'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final summary = record.summary.trim().isEmpty
        ? '请补充事件摘要。'
        : record.summary.trim();
    final notes = record.notes.trim();
    final notesBlock = notes.isEmpty ? '' : '\n## 备注\n\n$notes\n';
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n# ${record.displayName}\n\n$summary$notesBlock';
  }
}
