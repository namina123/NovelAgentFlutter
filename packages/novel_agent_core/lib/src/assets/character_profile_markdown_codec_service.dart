import '../packages/frontmatter_yaml_writer_service.dart';
import 'character_profile.dart';
import 'character_profile_normalizer_service.dart';

class CharacterProfileMarkdownCodecService {
  CharacterProfileMarkdownCodecService({
    CharacterProfileNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const CharacterProfileNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final CharacterProfileNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(CharacterProfile profile) {
    // 中文注释: 角色主档既要承接稳定身份，也要直接暴露“当前状态”给上下文选择层复用。
    final document = _normalizerService.toDocument(profile);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'display_name': document['display_name'],
      'summary': document['summary'],
      'current_status': document['current_status'],
      'current_state_summary': document['current_state_summary'],
      'latest_stage_label': document['latest_stage_label'],
      'latest_updated_at': document['latest_updated_at'],
      'latest_source_paths': document['latest_source_paths'],
      'aliases': document['aliases'],
      'name_history': document['name_history'],
      'story_role': document['story_role'],
      'traits': document['traits'],
      'organization_ids': document['organization_ids'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final summary = profile.summary.trim().isEmpty
        ? '请补充角色简介。'
        : profile.summary.trim();
    final sections = <String>[
      '---',
      _yamlWriterService.write(frontmatter),
      '---',
      '',
      '# ${profile.displayName}',
      '',
      summary,
    ];
    if (_hasRuntimeSnapshot(profile)) {
      sections.addAll(<String>[
        '',
        '## 当前状态',
        '',
        if (profile.currentStatus.trim().isNotEmpty)
          '- 状态：${profile.currentStatus.trim()}',
        if (profile.latestStageLabel.trim().isNotEmpty)
          '- 最近阶段：${profile.latestStageLabel.trim()}',
        if (profile.latestUpdatedAt.trim().isNotEmpty)
          '- 最近更新：${profile.latestUpdatedAt.trim()}',
        if (profile.latestSourcePaths.isNotEmpty)
          '- 参考路径：${profile.latestSourcePaths.join('、')}',
      ]);
      final snapshot = profile.currentStateSummary.trim();
      if (snapshot.isNotEmpty) {
        sections.addAll(<String>['', snapshot]);
      }
    }
    return '${sections.join('\n').trim()}\n';
  }

  bool _hasRuntimeSnapshot(CharacterProfile profile) {
    return profile.currentStatus.trim().isNotEmpty ||
        profile.currentStateSummary.trim().isNotEmpty ||
        profile.latestStageLabel.trim().isNotEmpty ||
        profile.latestUpdatedAt.trim().isNotEmpty ||
        profile.latestSourcePaths.isNotEmpty;
  }
}
