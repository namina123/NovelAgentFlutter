import '../common/json_types.dart';
import '../entity/entity_identity.dart';
import '../assets/style_profile.dart';
import '../assets/world_rule_set.dart';
import '../inspiration/inspiration_premise.dart';
import 'mode_guidance_asset_bundle.dart';

class ModeGuidanceAssetContextSectionService {
  const ModeGuidanceAssetContextSectionService();

  List<JsonMap> build(ModeGuidanceAssetBundle bundle) {
    // 中文注释: 该服务只把模式引导资产翻译成上下文片段，供执行链注入模型，不关心项目读取或持久化。
    final sections = <JsonMap>[];
    for (final premise in bundle.premises) {
      sections.add(
        _section(
          id: 'mode_premise_${_safeId(premise.id)}',
          title: '故事前提',
          priority: 98,
          creativeLayer: 'mode_guidance',
          source: bundle.markdownPathFor(premise.id),
          content: _premiseContent(premise),
        ),
      );
    }
    for (final style in bundle.styleProfiles) {
      sections.add(
        _section(
          id: 'mode_style_${_safeId(style.id)}',
          title: '风格锚点',
          priority: 97,
          creativeLayer: 'style',
          source: bundle.markdownPathFor(style.id),
          content: _styleContent(style),
        ),
      );
    }
    for (final world in bundle.worldRuleSets) {
      sections.add(
        _section(
          id: 'mode_world_${_safeId(world.id)}',
          title: '世界硬约束',
          priority: 96,
          creativeLayer: 'mode_guidance',
          source: bundle.markdownPathFor(world.id),
          content: _worldContent(world),
        ),
      );
    }
    for (final entity in bundle.entityIdentities) {
      sections.add(
        _section(
          id: 'mode_entity_${_safeId(entity.id)}',
          title: '角色/身份锚点',
          priority: 95,
          creativeLayer: 'mode_guidance',
          source: bundle.markdownPathFor(entity.id),
          content: _entityContent(entity),
        ),
      );
    }
    return sections;
  }

  String _premiseContent(InspirationPremise premise) {
    final lines = <String>[
      '前提档案：${premise.displayName}',
      '故事摘要：${premise.summary}',
    ];
    if (premise.corePromise.trim().isNotEmpty) {
      lines.add('核心承诺：${premise.corePromise.trim()}');
    }
    if (premise.mainConflict.trim().isNotEmpty) {
      lines.add('主线冲突：${premise.mainConflict.trim()}');
    }
    if (premise.boundaries.isNotEmpty) {
      lines.add('创作边界：');
      for (final boundary in premise.boundaries) {
        lines.add('- ${boundary.trim()}');
      }
    }
    return lines.join('\n');
  }

  JsonMap _section({
    required String id,
    required String title,
    required int priority,
    required String creativeLayer,
    required String source,
    required String content,
  }) {
    return <String, Object?>{
      'id': id,
      'title': title,
      'priority': priority,
      'creative_layer': creativeLayer,
      if (source.trim().isNotEmpty) 'source': source.trim(),
      'content': content.trim(),
    };
  }

  String _styleContent(StyleProfile style) {
    final lines = <String>[
      '风格档案：${style.displayName}',
      '核心风格：${style.summary}',
    ];
    if (style.guardrails.isNotEmpty) {
      lines.add('执行护栏：');
      for (final rule in style.guardrails) {
        lines.add('- ${rule.trim()}');
      }
    }
    return lines.join('\n');
  }

  String _worldContent(WorldRuleSet world) {
    final lines = <String>[
      '世界锚点：${world.displayName}',
      if (world.summary.trim().isNotEmpty) '摘要：${world.summary.trim()}',
    ];
    if (world.rules.isNotEmpty) {
      lines.add('必须遵守：');
      for (final rule in world.rules) {
        lines.add('- ${rule.trim()}');
      }
    }
    if (world.forbiddenAssumptions.isNotEmpty) {
      lines.add('禁止擅自追加：');
      for (final item in world.forbiddenAssumptions) {
        lines.add('- ${item.trim()}');
      }
    }
    return lines.join('\n');
  }

  String _entityContent(EntityIdentity entity) {
    final lines = <String>['实体类型：${entity.kind}', '显示名：${entity.displayName}'];
    if (entity.summary.trim().isNotEmpty) {
      lines.add('身份摘要：${entity.summary.trim()}');
    }
    if (entity.aliases.isNotEmpty) {
      lines.add('当前别名：${entity.aliases.join('、')}');
    }
    if (entity.nameHistory.isNotEmpty) {
      lines.add('历史命名：${entity.nameHistory.join('、')}');
    }
    return lines.join('\n');
  }

  String _safeId(String value) {
    return value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
  }
}
