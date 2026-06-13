import 'builtin_tool_catalog.dart';
import 'domain/narrative_domain_tool_names.dart';
import 'tool_capability_family_profile.dart';

class ToolCapabilityFamilyCatalogService {
  const ToolCapabilityFamilyCatalogService();

  static const String mountedReferenceConsumption =
      'mounted_reference_consumption';
  static const String writing = 'writing';
  static const String review = 'review';
  static const String research = 'research';
  static const String referenceExtraction = 'reference_extraction';
  static const String referenceMountCommit = 'reference_mount_commit';
  static const String continuousTaskControl = 'continuous_task_control';

  List<String> familyIds() {
    return const <String>[
      mountedReferenceConsumption,
      writing,
      review,
      research,
      referenceExtraction,
      referenceMountCommit,
      continuousTaskControl,
    ];
  }

  bool isKnownFamily(String familyId) {
    return familyIds().contains(familyId.trim());
  }

  String displayLabel(String familyId) {
    switch (familyId.trim()) {
      case mountedReferenceConsumption:
        return '挂载结果消费';
      case writing:
        return '写作交付';
      case review:
        return '审核复核';
      case research:
        return '研究采集';
      case referenceExtraction:
        return '参考提取归档';
      case referenceMountCommit:
        return '参考挂载提交';
      case continuousTaskControl:
        return '连续任务控制';
      default:
        return familyId.trim().isEmpty ? '未知能力族' : familyId.trim();
    }
  }

  List<ToolCapabilityFamilyProfile> builtinProfiles() {
    return const <ToolCapabilityFamilyProfile>[
      ToolCapabilityFamilyProfile(
        familyId: mountedReferenceConsumption,
        displayName: '挂载结果消费',
        description: '消费已经挂载到项目的信息与引用摘要，而不是重新切片源材料或直接改写挂载层事实源。',
        metadata: <String, Object?>{
          'consumption_mode': 'mounted_projection_only',
        },
      ),
      ToolCapabilityFamilyProfile(
        familyId: writing,
        displayName: '写作交付',
        description: '面向正文交付、叙事状态提交与约束绑定的写作能力族。',
        toolIds: <String>[
          NarrativeDomainToolNames.submitChapterDelivery,
          NarrativeDomainToolNames.submitNarrativeStateClaims,
          NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
          NarrativeDomainToolNames.proposeConstraintBinding,
        ],
      ),
      ToolCapabilityFamilyProfile(
        familyId: review,
        displayName: '审核复核',
        description: '面向结构化复核、澄清与 reviewer 建议提交的能力族。',
        toolIds: <String>[
          NarrativeDomainToolNames.submitSemanticReview,
          NarrativeDomainToolNames.requestProfileClarification,
        ],
      ),
      ToolCapabilityFamilyProfile(
        familyId: research,
        displayName: '研究采集',
        description: '面向外部研究请求与研究笔记沉淀的能力族。',
        toolIds: <String>[
          NarrativeDomainToolNames.requestExternalResearch,
          NarrativeDomainToolNames.submitResearchNote,
        ],
      ),
      ToolCapabilityFamilyProfile(
        familyId: referenceExtraction,
        displayName: '参考提取归档',
        description: '面向知识卡、设计元素、证据链接与引用作品边界归档的重型提取能力族。',
        toolIds: <String>[
          NarrativeDomainToolNames.proposeKnowledgeCard,
          NarrativeDomainToolNames.proposeDesignElement,
          NarrativeDomainToolNames.linkInformationEvidence,
          NarrativeDomainToolNames.proposeReferenceWork,
        ],
        metadata: <String, Object?>{'heavy_extraction': true},
      ),
      ToolCapabilityFamilyProfile(
        familyId: referenceMountCommit,
        displayName: '参考挂载提交',
        description: '面向 sqlite-first 挂载、投影确认与项目事实源提交的宿主侧能力族。',
        metadata: <String, Object?>{'host_contract_only': true},
      ),
      ToolCapabilityFamilyProfile(
        familyId: continuousTaskControl,
        displayName: '连续任务控制',
        description: '面向连续任务启动、队列推进与状态标记的控制面能力族。',
        toolIds: <String>[
          'start_long_task_run',
          'create_chapter_task',
          'mark_task_status',
        ],
        metadata: <String, Object?>{'host_or_supervisor_controlled': true},
      ),
    ];
  }

  ToolCapabilityFamilyProfile? profileFor(String familyId) {
    final normalized = familyId.trim();
    for (final profile in builtinProfiles()) {
      if (profile.familyId == normalized) {
        return profile;
      }
    }
    return null;
  }

  List<String> toolIdsForFamilies(Iterable<String> familyIds) {
    final result = <String>[];
    final seen = <String>{};
    for (final familyId in familyIds) {
      final profile = profileFor(familyId);
      if (profile == null) {
        continue;
      }
      for (final toolId in profile.toolIds) {
        final cleanToolId = toolId.trim();
        if (cleanToolId.isEmpty || !seen.add(cleanToolId)) {
          continue;
        }
        result.add(cleanToolId);
      }
    }
    return result;
  }

  bool containsKnownTool(String toolId) {
    final normalized = toolId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    for (final definition in BuiltinToolCatalog.definitions) {
      if (definition.id == normalized) {
        return true;
      }
    }
    return false;
  }

  List<String> unknownToolIds(Iterable<String> familyIds) {
    final result = <String>[];
    for (final toolId in toolIdsForFamilies(familyIds)) {
      if (!containsKnownTool(toolId)) {
        result.add(toolId);
      }
    }
    return result;
  }
}
