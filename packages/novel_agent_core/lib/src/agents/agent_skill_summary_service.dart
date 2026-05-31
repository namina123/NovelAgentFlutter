import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_skill_scope_service.dart';
import 'builtin_skill_group_catalog_service.dart';
import 'resolved_agent_skill_loadout.dart';

class AgentSkillSummaryService {
  AgentSkillSummaryService({
    AgentSkillScopeService? skillScopeService,
    BuiltinSkillGroupCatalogService? skillGroupCatalogService,
  }) : _skillScopeService = skillScopeService ?? AgentSkillScopeService(),
       _skillGroupCatalogService =
           skillGroupCatalogService ?? const BuiltinSkillGroupCatalogService();

  final AgentSkillScopeService _skillScopeService;
  final BuiltinSkillGroupCatalogService _skillGroupCatalogService;

  List<JsonMap> buildAvailableSkillSummaries({
    required JsonMap agent,
    required List<Object?> allSkills,
    List<Object?> availableSkillGroups = const <Object?>[],
    ResolvedAgentSkillLoadout? resolvedLoadout,
  }) {
    // 中文注释: 技能摘要只返回模型做二次选择所需的最小信息，不把整份技能正文提前塞进上下文。
    final skillById = <String, JsonMap>{};
    for (final rawSkill in allSkills) {
      final skill = ValueReaders.mapValue(rawSkill);
      final id = ValueReaders.stringValue(skill['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      skillById[id] = skill;
    }
    final allowedIds =
        resolvedLoadout?.finalSkillIds ??
        _skillScopeService.enabledSkillIds(
          agent,
          availableSkillGroups: availableSkillGroups.isEmpty
              ? _skillGroupCatalogService.builtinGroups()
              : availableSkillGroups,
          availableSkillIds: skillById.keys.toList(growable: false),
        );
    final result = <JsonMap>[];
    for (final skillId in allowedIds) {
      final skill = skillById[skillId];
      if (skill == null || skill.isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        'id': skillId,
        'name': ValueReaders.stringValue(skill['name'], skillId),
        'description': _clipText(
          ValueReaders.stringValue(skill['description']),
          140,
        ),
        'trigger': _clipText(
          ValueReaders.stringList(skill['activation_hints']).join('；'),
          160,
        ),
        'source': ValueReaders.stringValue(skill['source']),
        'source_scope': ValueReaders.stringValue(skill['source_scope']),
      });
    }
    return result;
  }

  String selectSkillIdForQuery(String query, List<Object?> summaries) {
    // 中文注释: 查询匹配保持轻量可解释，优先照顾中文整句匹配，再用分词 token 做补充计分。
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return '';
    }
    final queryTokens = _queryTokens(cleanQuery);
    var bestId = '';
    var bestScore = 0;
    for (final rawSummary in summaries) {
      final summary = ValueReaders.mapValue(rawSummary);
      if (summary.isEmpty) {
        continue;
      }
      final haystack = <String>[
        ValueReaders.stringValue(summary['id']),
        ValueReaders.stringValue(summary['name']),
        ValueReaders.stringValue(summary['description']),
        ValueReaders.stringValue(summary['trigger']),
      ].join('\n').toLowerCase();
      var score = 0;
      if (haystack.contains(cleanQuery)) {
        score += cleanQuery.length * 2;
      }
      for (final token in queryTokens) {
        if (haystack.contains(token)) {
          score += token.length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestId = ValueReaders.stringValue(summary['id']).trim();
      }
    }
    return bestId;
  }

  List<String> _queryTokens(String cleanQuery) {
    final tokens = cleanQuery
        .split(RegExp(r'[\s,，、;；/|]+'))
        .map((token) => token.trim())
        .where((token) => token.length >= 2)
        .toList(growable: true);
    if (cleanQuery.length >= 2) {
      for (var index = 0; index < cleanQuery.length - 1; index += 1) {
        final token = cleanQuery.substring(index, index + 2).trim();
        if (token.length < 2 || tokens.contains(token)) {
          continue;
        }
        tokens.add(token);
      }
    }
    return tokens;
  }

  String _clipText(String text, int maxChars) {
    final cleanText = text.trim();
    if (cleanText.length <= maxChars) {
      return cleanText;
    }
    return '${cleanText.substring(0, maxChars - 1)}...';
  }
}
