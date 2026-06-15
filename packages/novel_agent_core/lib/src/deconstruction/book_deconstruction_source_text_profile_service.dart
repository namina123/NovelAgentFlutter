import '../assets/character_profile.dart';
import '../assets/organization_profile.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';

class BookDeconstructionSourceTextProfileService {
  const BookDeconstructionSourceTextProfileService();

  List<StyleProfile> styleProfilesOf(String styleSummary) {
    // 中文注释: 风格提要只做最小结构化收束，不承担解释性扩写。
    final cleanSummary = styleSummary.trim();
    if (cleanSummary.isEmpty) {
      return const <StyleProfile>[];
    }
    return <StyleProfile>[
      StyleProfile(
        id: 'deconstruction_style',
        displayName: '拆书风格提要',
        summary: cleanSummary,
      ),
    ];
  }

  List<WorldRuleSet> worldRuleSetsOf(String worldRulesText) {
    // 中文注释: 世界规则提要只把非空行收束成规则集合，不做额外推断。
    final rules = _lineValues(worldRulesText);
    if (rules.isEmpty) {
      return const <WorldRuleSet>[];
    }
    return <WorldRuleSet>[
      WorldRuleSet(
        id: 'world_rules',
        displayName: '世界规则提要',
        summary: rules.first,
        rules: rules,
      ),
    ];
  }

  List<CharacterProfile> characterProfilesOf(String characterLinesText) {
    // 中文注释: 角色条目按行切分并保留可读显示名，避免 app 层自己拼解析规则。
    return _lineValues(characterLinesText).asMap().entries.map((entry) {
      final parsed = _nameSummaryPair(entry.value);
      return CharacterProfile(
        id: _safeId(parsed.$1, fallback: 'character_${entry.key + 1}'),
        displayName: parsed.$1,
        summary: parsed.$2,
      );
    }).toList(growable: false);
  }

  List<OrganizationProfile> organizationProfilesOf(
    String organizationLinesText,
  ) {
    // 中文注释: 组织条目同样只做轻量结构化，保持和角色条目一致的规则。
    return _lineValues(organizationLinesText).asMap().entries.map((entry) {
      final parsed = _nameSummaryPair(entry.value);
      return OrganizationProfile(
        id: _safeId(parsed.$1, fallback: 'organization_${entry.key + 1}'),
        displayName: parsed.$1,
        summary: parsed.$2,
      );
    }).toList(growable: false);
  }

  List<String> _lineValues(String rawText) {
    return rawText
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  (String, String) _nameSummaryPair(String rawLine) {
    final match = RegExp(r'^([^:：\-]+)\s*[:：\-]\s*(.+)$').firstMatch(rawLine);
    if (match == null) {
      return (rawLine.trim(), '');
    }
    return ((match.group(1) ?? '').trim(), (match.group(2) ?? '').trim());
  }

  String _safeId(String value, {required String fallback}) {
    final clean = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (clean.isEmpty) {
      return fallback;
    }
    return clean;
  }
}
