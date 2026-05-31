import '../packages/frontmatter_yaml_writer_service.dart';
import 'character_stage_state_record.dart';
import 'character_stage_state_record_normalizer_service.dart';

class CharacterStageStateRecordMarkdownCodecService {
  CharacterStageStateRecordMarkdownCodecService({
    CharacterStageStateRecordNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ??
           const CharacterStageStateRecordNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final CharacterStageStateRecordNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(CharacterStageStateRecord record) {
    // 中文注释: latest 状态快照保持 Markdown，可直接被读侧、探针和人工排查复用。
    final document = _normalizerService.toDocument(record);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'character_id': document['character_id'],
      'display_name': document['display_name'],
      'stage_id': document['stage_id'],
      'stage_label': document['stage_label'],
      'status': document['status'],
      'source_paths': document['source_paths'],
      'related_timeline_ids': document['related_timeline_ids'],
      'updated_at': document['updated_at'],
      'metadata': document['metadata'],
    };
    final body = record.summary.trim().isEmpty
        ? '本次未提供额外状态说明。'
        : record.summary.trim();
    final lines = <String>[
      '---',
      _yamlWriterService.write(frontmatter),
      '---',
      '',
      '# ${record.displayName} 阶段状态',
      '',
      if (record.stageLabel.trim().isNotEmpty)
        '- 阶段：${record.stageLabel.trim()}',
      if (record.status.trim().isNotEmpty) '- 状态：${record.status.trim()}',
      if (record.updatedAt.trim().isNotEmpty)
        '- 更新时间：${record.updatedAt.trim()}',
      if (record.sourcePaths.isNotEmpty) '- 来源：${record.sourcePaths.join('、')}',
      '',
      body,
    ];
    return '${lines.join('\n').trim()}\n';
  }
}
