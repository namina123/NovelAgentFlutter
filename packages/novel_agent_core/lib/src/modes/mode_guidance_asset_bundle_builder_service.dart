import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import '../entity/entity_identity.dart';
import 'mode_guidance_asset_bundle.dart';
import 'mode_guidance_state.dart';

class ModeGuidanceAssetBundleBuilderService {
  const ModeGuidanceAssetBundleBuilderService();

  ModeGuidanceAssetBundle build(ModeGuidanceState state) {
    // 中文注释: 模式引导状态在这里被压缩成可复用资产，避免后续运行层只能反复啃摘要 Markdown。
    switch (state.modeId) {
      case 'seed_autopilot_novel':
        return _buildSeedAutopilotBundle(state);
      case 'full_outline_consensus':
        return _buildFullOutlineBundle(state);
      default:
        return ModeGuidanceAssetBundle(modeId: state.modeId);
    }
  }

  ModeGuidanceAssetBundle _buildSeedAutopilotBundle(ModeGuidanceState state) {
    final values = _answerValues(state);
    final styleTarget = _value(values, 'style_target');
    final corePromise = _value(values, 'core_promise');
    final autonomyGuardrails = _value(values, 'autonomy_guardrails');
    final worldAnchor = _value(values, 'world_anchor');
    final protagonistDrive = _value(values, 'protagonist_drive');
    final styles = <StyleProfile>[];
    final worlds = <WorldRuleSet>[];
    final entities = <EntityIdentity>[];
    final markdownPaths = <String, String>{};
    if (styleTarget.isNotEmpty) {
      const assetId = 'seed_autopilot.primary_style';
      styles.add(
        StyleProfile(
          id: assetId,
          displayName: '默认风格锚点',
          summary: styleTarget,
          guardrails: _nonEmptyLines(<String>[corePromise, autonomyGuardrails]),
        ),
      );
      markdownPaths[assetId] = 'styles/seed_autopilot_style.md';
    }
    if (worldAnchor.isNotEmpty) {
      const assetId = 'seed_autopilot.primary_world';
      worlds.add(
        WorldRuleSet(
          id: assetId,
          displayName: '默认世界锚点',
          summary: worldAnchor,
          rules: _splitParagraphRules(worldAnchor),
        ),
      );
      markdownPaths[assetId] = 'world/seed_autopilot_world_anchor.md';
    }
    if (protagonistDrive.isNotEmpty) {
      const assetId = 'seed_autopilot.primary_protagonist';
      entities.add(
        EntityIdentity(
          id: assetId,
          kind: 'character',
          displayName: '主角',
          summary: protagonistDrive,
        ),
      );
      markdownPaths[assetId] = 'characters/seed_autopilot_protagonist.md';
    }
    return ModeGuidanceAssetBundle(
      modeId: state.modeId,
      styleProfiles: styles,
      worldRuleSets: worlds,
      entityIdentities: entities,
      markdownPathsByAssetId: markdownPaths,
    );
  }

  ModeGuidanceAssetBundle _buildFullOutlineBundle(ModeGuidanceState state) {
    final values = _answerValues(state);
    final styleTarget = _value(values, 'style_and_boundaries');
    final premise = _value(values, 'book_premise');
    final mainArc = _value(values, 'main_arc');
    final entities = <EntityIdentity>[];
    final styles = <StyleProfile>[];
    final markdownPaths = <String, String>{};
    if (styleTarget.isNotEmpty) {
      const assetId = 'full_outline.primary_style';
      styles.add(
        StyleProfile(
          id: assetId,
          displayName: '全书共识风格',
          summary: styleTarget,
          guardrails: _nonEmptyLines(<String>[mainArc]),
        ),
      );
      markdownPaths[assetId] = 'styles/full_outline_consensus_style.md';
    }
    if (premise.isNotEmpty || mainArc.isNotEmpty) {
      const assetId = 'full_outline.primary_story_focus';
      entities.add(
        EntityIdentity(
          id: assetId,
          kind: 'character',
          displayName: '主角焦点',
          summary: _nonEmptyLines(<String>[premise, mainArc]).join(' '),
        ),
      );
      markdownPaths[assetId] =
          'characters/full_outline_consensus_core_roles.md';
    }
    return ModeGuidanceAssetBundle(
      modeId: state.modeId,
      styleProfiles: styles,
      entityIdentities: entities,
      markdownPathsByAssetId: markdownPaths,
    );
  }

  Map<String, String> _answerValues(ModeGuidanceState state) {
    final values = <String, String>{};
    for (final answer in state.answers) {
      values[answer.fieldKey] = answer.value.trim();
    }
    return values;
  }

  String _value(Map<String, String> values, String key) {
    return values[key] ?? '';
  }

  List<String> _nonEmptyLines(List<String> rawValues) {
    final lines = <String>[];
    for (final rawValue in rawValues) {
      final cleanValue = rawValue.trim();
      if (cleanValue.isNotEmpty) {
        lines.add(cleanValue);
      }
    }
    return lines;
  }

  List<String> _splitParagraphRules(String rawText) {
    final normalized = rawText
        .replaceAll('；', '。')
        .replaceAll(';', '.')
        .replaceAll('\r', '\n');
    final fragments = normalized.split(RegExp(r'[。\n]+'));
    final rules = <String>[];
    for (final fragment in fragments) {
      final cleanFragment = fragment.trim();
      if (cleanFragment.isNotEmpty) {
        rules.add(cleanFragment);
      }
    }
    if (rules.isNotEmpty) {
      return rules;
    }
    final fallback = rawText.trim();
    return fallback.isEmpty ? const <String>[] : <String>[fallback];
  }
}
