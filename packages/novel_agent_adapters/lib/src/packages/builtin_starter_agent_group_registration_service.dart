import 'package:novel_agent_core/novel_agent_core.dart';

class BuiltinStarterAgentGroupRegistrationService {
  BuiltinStarterAgentGroupRegistrationService({
    AgentGroupNormalizerService? normalizerService,
  }) : _normalizerService = normalizerService ?? AgentGroupNormalizerService();

  final AgentGroupNormalizerService _normalizerService;

  List<JsonMap> registeredGroups() {
    // 中文注释: 这批 starter groups 先只提供稳定的单成员默认组，后续再扩成更丰富的项目专用协作组。
    return _rawStarterGroups
        .map(_normalizerService.normalizeAgentGroup)
        .toList(growable: false);
  }

  static const List<JsonMap> _rawStarterGroups = <JsonMap>[
    <String, Object?>{
      'id': 'starter_novel_generalist',
      'name': '默认小说开局组',
      'description': '面向普通小说项目的默认单智能体开局组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认小说开局',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['novel'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
        ],
      },
    },
    <String, Object?>{
      'id': 'starter_long_novel_seed_generalist',
      'name': '默认长任务灵感开局组',
      'description': '面向 seed-driven 长任务项目的默认单智能体开局组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认长任务灵感开局',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['long_novel'],
        'required_trait_ids': <String>['long_task', 'seed_driven'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
        ],
      },
    },
    <String, Object?>{
      'id': 'starter_long_novel_full_outline_generalist',
      'name': '默认长任务全纲开局组',
      'description': '面向 full-outline 长任务项目的默认单智能体开局组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认长任务全纲开局',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['long_novel'],
        'required_trait_ids': <String>['long_task', 'full_outline'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
        ],
      },
    },
    <String, Object?>{
      'id': 'starter_knowledge_base_generalist',
      'name': '默认知识库整理组',
      'description': '面向知识库项目的默认单智能体整理组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认知识库整理',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['knowledge_base'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
          ToolCapabilityFamilyCatalogService.referenceExtraction,
        ],
      },
    },
    <String, Object?>{
      'id': 'starter_short_collection_generalist',
      'name': '默认短文集开局组',
      'description': '面向短文集项目的默认单智能体开局组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认短文集开局',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['short_collection'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.writing,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
        ],
      },
    },
    <String, Object?>{
      'id': 'starter_book_deconstruction_generalist',
      'name': '默认拆书整理组',
      'description': '面向拆书项目的默认单智能体整理组。',
      'source': 'builtin',
      'enabled': true,
      'orchestration': 'supervised',
      'agents': <String>['default_generalist'],
      'primary_agent_id': 'default_generalist',
      'required_agent_ids': <String>['default_generalist'],
      'display_label': '默认拆书整理',
      'recommended_by_default': true,
      'applicability_scope': <String, Object?>{
        'allowed_project_type_ids': <String>['book_deconstruction'],
      },
      'metadata': <String, Object?>{
        'starter_group': true,
        'starter_kind': 'single_agent',
        'tool_capability_family_ids': <String>[
          ToolCapabilityFamilyCatalogService.mountedReferenceConsumption,
          ToolCapabilityFamilyCatalogService.review,
          ToolCapabilityFamilyCatalogService.research,
          ToolCapabilityFamilyCatalogService.referenceExtraction,
        ],
      },
    },
  ];
}
