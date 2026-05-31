import 'package:novel_agent_core/novel_agent_core.dart';

class BuiltinExpressionConstraintProfileRegistrationService {
  BuiltinExpressionConstraintProfileRegistrationService({
    ExpressionConstraintProfileNormalizerService? normalizerService,
  }) : _normalizerService =
           normalizerService ??
           const ExpressionConstraintProfileNormalizerService();

  final ExpressionConstraintProfileNormalizerService _normalizerService;

  List<ExpressionConstraintProfile> registeredProfiles() {
    // 中文注释: 这一批 builtin preset 先只提供稳定的常用表达限制，后续再扩更多平台化或项目专用约束。
    return _rawProfiles
        .map(_normalizerService.normalize)
        .toList(growable: false);
  }

  static const List<JsonMap> _rawProfiles = <JsonMap>[
    <String, Object?>{
      'id': 'de_ai',
      'display_name': '去 AI 风',
      'summary': '降低模板化表达、解释腔和过度工整的平衡句。',
      'kind': 'natural_expression',
      'rules': <Object?>[
        '少用工整排比、假深刻总结和万能收束句。',
        '能通过动作、对话、感官与后果显现时，不先用抽象解释句概括。',
        '允许句子保留少量粗粝、迟疑和不圆满，不强求每句都像标准答案。',
      ],
      'risk_signals': <Object?>[
        '不是……而是……',
        '并非……而是……',
        '总而言之',
        '值得一提的是',
        '这一刻改变了一切',
      ],
      'recommended_scope': <String, Object?>{
        'project_type_ids': <Object?>[
          'novel',
          'long_novel',
          'short_collection',
        ],
      },
      'metadata': <String, Object?>{
        'builtin': true,
        'source': 'builtin',
        'source_path': 'builtin://expression_constraints/de_ai',
      },
    },
    <String, Object?>{
      'id': 'strict_pov_boundary',
      'display_name': '严格 POV 边界',
      'summary': '压制未知信息越界、视角泄漏与叙事边界松动。',
      'kind': 'narrative_boundary',
      'rules': <Object?>[
        '只允许写入当前 POV 合理可知的信息、判断和感受。',
        '不要让叙述者替角色提前总结他尚未意识到的因果。',
        '涉及他人隐秘动机和未来判断时，除非现场有可观察证据，否则不要代为揭示。',
      ],
      'risk_signals': <Object?>['他并不知道', '她不会想到', '实际上', '与此同时在另一边'],
      'recommended_scope': <String, Object?>{
        'project_type_ids': <Object?>['novel', 'long_novel'],
      },
      'metadata': <String, Object?>{
        'builtin': true,
        'source': 'builtin',
        'source_path': 'builtin://expression_constraints/strict_pov_boundary',
      },
    },
    <String, Object?>{
      'id': 'low_jargon_narration',
      'display_name': '降低术语分析腔',
      'summary': '压低职业化、理论化、方案化的抽象分析词入侵正文。',
      'kind': 'terminology_control',
      'rules': <Object?>[
        '如果可以转成动作、后果、对话或场面，不优先保留抽象分析词。',
        '除非 POV 身份、时代背景或设定真的需要，否则不要让正文频繁使用评论员式术语。',
        '优先写可感知的压力、冲突与代价，而不是先写机制、结构或底层逻辑。',
      ],
      'risk_signals': <Object?>['机制', '结构', '逻辑', '校准', '底层逻辑', '闭环', '赋能'],
      'recommended_scope': <String, Object?>{
        'project_type_ids': <Object?>['novel', 'long_novel', 'knowledge_base'],
      },
      'metadata': <String, Object?>{
        'builtin': true,
        'source': 'builtin',
        'source_path': 'builtin://expression_constraints/low_jargon_narration',
      },
    },
  ];
}
