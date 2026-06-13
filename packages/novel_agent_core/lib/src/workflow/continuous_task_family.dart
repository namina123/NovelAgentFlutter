import '../agents/agent_task_family.dart';

abstract final class ContinuousTaskFamilies {
  static const String longFormWriting = 'long_form_writing';
  static const String goalMode = 'goal_mode';
  static const String referenceExtraction =
      AgentTaskFamilies.referenceExtraction;
  static const String researchConsolidation = AgentTaskFamilies.research;

  static const List<String> values = <String>[
    longFormWriting,
    goalMode,
    referenceExtraction,
    researchConsolidation,
  ];

  static bool contains(String candidate) {
    // 中文注释: 连续任务族采用开放字符串合同，但这里仍提供稳定白名单，方便 focused tests 与后续 profile resolver 做边界校验。
    return values.contains(candidate.trim());
  }
}
