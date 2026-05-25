import 'runtime_baseline.dart';

class RuntimeBaselineCatalogService {
  const RuntimeBaselineCatalogService();

  static const List<RuntimeBaseline> _baselines = <RuntimeBaseline>[
    RuntimeBaseline(
      id: 'continuous_autonomous',
      title: '连续托管式',
      description: '人类先给灵感、边界和长期约束，后续由智能体持续推进，只在关键检查点回到确认。',
      supportedProjectTypeIds: <String>['long_novel'],
      defaultHeartbeatInterval: Duration(seconds: 45),
      waitingGateHeartbeatInterval: Duration(seconds: 90),
      recoveringHeartbeatInterval: Duration(seconds: 20),
      staleAfter: Duration(minutes: 5),
      unattended: true,
      keepAliveAcrossProjectSwitch: true,
      autoAdvanceChapters: true,
    ),
    RuntimeBaseline(
      id: 'chapter_collaboration_autorun',
      title: '逐章协作式自动推进',
      description: '每章都走生成、审稿与返工链，但无需用户逐章点下一步，适合更稳的自动推进。',
      supportedProjectTypeIds: <String>['long_novel'],
      defaultHeartbeatInterval: Duration(seconds: 30),
      waitingGateHeartbeatInterval: Duration(seconds: 60),
      recoveringHeartbeatInterval: Duration(seconds: 15),
      staleAfter: Duration(minutes: 4),
      unattended: true,
      keepAliveAcrossProjectSwitch: true,
      autoAdvanceChapters: true,
    ),
  ];

  List<RuntimeBaseline> all() {
    return List<RuntimeBaseline>.unmodifiable(
      _baselines.where((baseline) => baseline.enabled),
    );
  }

  List<RuntimeBaseline> forProjectType(String projectTypeId) {
    // 中文注释: 运行基准目录按项目类型过滤，避免普通项目误看到长任务运行基线。
    return List<RuntimeBaseline>.unmodifiable(
      all().where((baseline) => baseline.supportsProjectType(projectTypeId)),
    );
  }

  RuntimeBaseline? byId(String baselineId) {
    final cleanBaselineId = baselineId.trim();
    for (final baseline in all()) {
      if (baseline.id == cleanBaselineId) {
        return baseline;
      }
    }
    return null;
  }

  String normalizeForProjectType(String projectTypeId, String baselineId) {
    // 中文注释: 只有当前项目类型可用的运行基线才允许留下，未知值统一回退为空。
    final cleanBaselineId = baselineId.trim();
    for (final baseline in forProjectType(projectTypeId)) {
      if (baseline.id == cleanBaselineId) {
        return baseline.id;
      }
    }
    return '';
  }
}
