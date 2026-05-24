import 'dart:convert';

import '../agents/agent_group_normalizer_service.dart';
import '../agents/agent_profile_normalizer_service.dart';
import '../agents/skill_group_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/skill_markdown_package_parser_service.dart';
import 'customization_root_catalog_service.dart';

class CustomizationBundleImportPreviewService {
  CustomizationBundleImportPreviewService({
    AgentProfileNormalizerService? agentNormalizerService,
    SkillMarkdownPackageParserService? skillParserService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    CustomizationRootCatalogService? rootCatalogService,
  }) : _agentNormalizerService =
           agentNormalizerService ?? AgentProfileNormalizerService(),
       _skillParserService =
           skillParserService ?? SkillMarkdownPackageParserService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService(),
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _rootCatalogService =
           rootCatalogService ?? const CustomizationRootCatalogService();

  final AgentProfileNormalizerService _agentNormalizerService;
  final SkillMarkdownPackageParserService _skillParserService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final CustomizationRootCatalogService _rootCatalogService;

  JsonMap previewBundle({
    required JsonMap bundle,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<JsonMap> projectAgents,
    required List<JsonMap> projectSkills,
    required List<JsonMap> projectSkillGroups,
    required List<JsonMap> projectAgentGroups,
    required List<JsonMap> builtinAgents,
    required List<JsonMap> builtinSkills,
    required List<JsonMap> builtinSkillGroups,
    required List<JsonMap> builtinAgentGroups,
  }) {
    // 中文注释: 导入预检只做归一化和冲突分析，不写盘，方便 UI 和 CLI 共用同一规则。
    if (ValueReaders.stringValue(bundle['kind']).trim().isNotEmpty &&
        ValueReaders.stringValue(bundle['kind']).trim() !=
            'novel_agent_customization_bundle') {
      return <String, Object?>{
        'ok': false,
        'error': 'Unsupported customization bundle.',
        'items': const <Object?>[],
        'summary': const <String, Object?>{},
      };
    }
    final summary = <String, Object?>{
      'total': 0,
      'new': 0,
      'project_conflicts': 0,
      'will_overwrite': 0,
      'skipped': 0,
      'builtin_overrides': 0,
      'blocked_builtin_overrides': 0,
      'invalid': 0,
    };
    final items = <JsonMap>[];
    _previewSection(
      rawItems: ValueReaders.mapList(bundle['skills']),
      root: CustomizationRootCatalogService.skillsRoot,
      kind: 'skill',
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      projectEntries: projectSkills,
      builtinEntries: builtinSkills,
      items: items,
      summary: summary,
    );
    _previewSection(
      rawItems: ValueReaders.mapList(bundle['skill_groups']),
      root: CustomizationRootCatalogService.skillGroupsRoot,
      kind: 'skill_group',
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      projectEntries: projectSkillGroups,
      builtinEntries: builtinSkillGroups,
      items: items,
      summary: summary,
    );
    _previewSection(
      rawItems: ValueReaders.mapList(bundle['agents']),
      root: CustomizationRootCatalogService.agentsRoot,
      kind: 'agent',
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      projectEntries: projectAgents,
      builtinEntries: builtinAgents,
      items: items,
      summary: summary,
    );
    _previewSection(
      rawItems: ValueReaders.mapList(bundle['agent_groups']),
      root: CustomizationRootCatalogService.agentGroupsRoot,
      kind: 'agent_group',
      overwrite: overwrite,
      allowBuiltinShadow: allowBuiltinShadow,
      projectEntries: projectAgentGroups,
      builtinEntries: builtinAgentGroups,
      items: items,
      summary: summary,
    );
    return <String, Object?>{
      'ok': ValueReaders.intValue(summary['invalid']) == 0,
      'error': ValueReaders.intValue(summary['invalid']) == 0
          ? ''
          : 'Bundle contains invalid customization entries.',
      'title': ValueReaders.stringValue(bundle['title']),
      'description': ValueReaders.stringValue(bundle['description']),
      'items': items,
      'summary': summary,
    };
  }

  void _previewSection({
    required List<JsonMap> rawItems,
    required String root,
    required String kind,
    required bool overwrite,
    required bool allowBuiltinShadow,
    required List<JsonMap> projectEntries,
    required List<JsonMap> builtinEntries,
    required List<JsonMap> items,
    required JsonMap summary,
  }) {
    final projectById = _byId(projectEntries);
    final builtinById = _byId(builtinEntries);
    final entryFileName = _entryFileName(root);
    for (final rawItem in rawItems) {
      summary['total'] = ValueReaders.intValue(summary['total']) + 1;
      final normalized = _normalizeBundleItem(rawItem, kind);
      final itemId = ValueReaders.stringValue(normalized['id']).trim();
      if (itemId.isEmpty) {
        summary['invalid'] = ValueReaders.intValue(summary['invalid']) + 1;
        items.add(<String, Object?>{
          'kind': kind,
          'status': 'invalid',
          'action': 'skip',
          'error': 'Missing id.',
        });
        continue;
      }
      final targetPath = '$root/$itemId/$entryFileName';
      final projectExisting = projectById[itemId] ?? const <String, Object?>{};
      final builtinExisting = builtinById[itemId] ?? const <String, Object?>{};
      var status = 'new';
      var action = 'create';
      if (projectExisting.isNotEmpty) {
        status = 'project_conflict';
        action = overwrite ? 'overwrite' : 'skip';
        summary['project_conflicts'] =
            ValueReaders.intValue(summary['project_conflicts']) + 1;
        if (overwrite) {
          summary['will_overwrite'] =
              ValueReaders.intValue(summary['will_overwrite']) + 1;
        } else {
          summary['skipped'] = ValueReaders.intValue(summary['skipped']) + 1;
        }
      } else if (builtinExisting.isNotEmpty) {
        status = 'builtin_override';
        if (allowBuiltinShadow) {
          action = 'create_override';
          summary['builtin_overrides'] =
              ValueReaders.intValue(summary['builtin_overrides']) + 1;
        } else {
          action = 'skip_builtin';
          summary['blocked_builtin_overrides'] =
              ValueReaders.intValue(summary['blocked_builtin_overrides']) + 1;
          summary['skipped'] = ValueReaders.intValue(summary['skipped']) + 1;
        }
      } else {
        summary['new'] = ValueReaders.intValue(summary['new']) + 1;
      }
      final existing = projectExisting.isNotEmpty
          ? projectExisting
          : builtinExisting;
      items.add(<String, Object?>{
        'kind': kind,
        'id': itemId,
        'name': ValueReaders.stringValue(normalized['name'], itemId),
        'status': status,
        'action': action,
        'target_path': targetPath,
        'existing_name': ValueReaders.stringValue(existing['name']),
        'incoming_name': ValueReaders.stringValue(normalized['name']),
        'changed_fields': _changedFieldNames(existing, normalized),
        'source': ValueReaders.stringValue(normalized['source'], 'bundle'),
      });
    }
  }

  JsonMap _normalizeBundleItem(JsonMap item, String kind) {
    switch (kind) {
      case 'agent':
        final normalized = _agentNormalizerService.normalizeAgentProfile(item);
        return <String, Object?>{
          ...normalized,
          'source': 'bundle',
          'source_scope': 'bundle',
        };
      case 'skill':
        final normalized = _skillParserService.parsePackage(
          jsonEncode(item),
          fallbackId: ValueReaders.stringValue(item['id']),
        );
        return <String, Object?>{
          ...normalized,
          'source': 'bundle',
          'source_scope': 'bundle',
        };
      case 'skill_group':
        final normalized = _skillGroupNormalizerService.normalizeSkillGroup(
          item,
        );
        return <String, Object?>{...normalized, 'source': 'bundle'};
      case 'agent_group':
        final normalized = _agentGroupNormalizerService.normalizeAgentGroup(
          item,
        );
        return <String, Object?>{...normalized, 'source': 'bundle'};
      default:
        return const <String, Object?>{};
    }
  }

  Map<String, JsonMap> _byId(List<JsonMap> entries) {
    final result = <String, JsonMap>{};
    for (final entry in entries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isNotEmpty) {
        result[id] = ValueReaders.deepCopyMap(entry);
      }
    }
    return result;
  }

  String _entryFileName(String root) {
    for (final descriptor in _rootCatalogService.roots()) {
      if (descriptor['root'] == root) {
        return descriptor['entry_file'] ?? 'entry.json';
      }
    }
    return 'entry.json';
  }

  List<String> _changedFieldNames(JsonMap existing, JsonMap incoming) {
    if (existing.isEmpty) {
      return const <String>[];
    }
    final keys = <String>{
      ...existing.keys,
      ...incoming.keys,
    }.toList(growable: false)..sort();
    final changed = <String>[];
    for (final key in keys) {
      if (const <String>{
        'updated_at',
        'relative_path',
        'project_relative_path',
        'entry_file_path',
        'schema_version',
      }.contains(key)) {
        continue;
      }
      if (jsonEncode(existing[key]) != jsonEncode(incoming[key])) {
        changed.add(key);
      }
    }
    return changed;
  }
}
