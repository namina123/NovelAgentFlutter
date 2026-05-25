import '../packages/frontmatter_yaml_writer_service.dart';
import 'foreshadow_record.dart';
import 'foreshadow_record_normalizer_service.dart';

class ForeshadowRecordMarkdownCodecService {
  ForeshadowRecordMarkdownCodecService({
    ForeshadowRecordNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const ForeshadowRecordNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final ForeshadowRecordNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(ForeshadowRecord record) {
    // 中文注释: 伏笔资产落成 Markdown 后，GUI/CLI 都能按普通项目文件浏览和编辑。
    final document = _normalizerService.toDocument(record);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'title': document['title'],
      'status': document['status'],
      'planted_chapter_path': document['planted_chapter_path'],
      'target_payoff_path': document['target_payoff_path'],
      'related_entity_ids': document['related_entity_ids'],
      'related_timeline_ids': document['related_timeline_ids'],
      'related_relationship_ids': document['related_relationship_ids'],
      'related_paths': document['related_paths'],
      'trigger_conditions': document['trigger_conditions'],
      'payoff_expectations': document['payoff_expectations'],
      'tags': document['tags'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final summary = record.summary.trim().isEmpty
        ? '请补充伏笔摘要。'
        : record.summary.trim();
    final notes = record.notes.trim();
    final notesBlock = notes.isEmpty ? '' : '\n## 备注\n\n$notes\n';
    return '---\n${_yamlWriterService.write(frontmatter)}\n---\n\n# ${record.title}\n\n$summary$notesBlock';
  }
}
