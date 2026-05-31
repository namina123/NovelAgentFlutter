import '../packages/frontmatter_yaml_writer_service.dart';
import 'organization_profile.dart';
import 'organization_profile_normalizer_service.dart';

class OrganizationProfileMarkdownCodecService {
  OrganizationProfileMarkdownCodecService({
    OrganizationProfileNormalizerService? normalizerService,
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _normalizerService =
           normalizerService ?? const OrganizationProfileNormalizerService(),
       _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  final OrganizationProfileNormalizerService _normalizerService;
  final FrontmatterYamlWriterService _yamlWriterService;

  String encode(OrganizationProfile profile) {
    // 中文注释: 组织卡导出成 Markdown 时保持与角色/风格一致的 frontmatter 结构，方便目录包与项目内资产共用。
    final document = _normalizerService.toDocument(profile);
    final frontmatter = <String, Object?>{
      'id': document['id'],
      'display_name': document['display_name'],
      'summary': document['summary'],
      'aliases': document['aliases'],
      'name_history': document['name_history'],
      'organization_type': document['organization_type'],
      'member_character_ids': document['member_character_ids'],
      'source_path': document['source_path'],
      'metadata': document['metadata'],
    };
    final summary = profile.summary.trim().isEmpty
        ? '请补充组织简介。'
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
    if (profile.memberCharacterIds.isNotEmpty) {
      sections.addAll(<String>[
        '',
        '## 成员',
        '',
        ...profile.memberCharacterIds.map((memberId) => '- $memberId'),
      ]);
    }
    return '${sections.join('\n').trim()}\n';
  }
}
