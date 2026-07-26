import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/runtime_label_service.dart';

class ProjectSubtitleViewDataService {
  ProjectSubtitleViewDataService({
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RuntimeLabelService? runtimeLabelService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runtimeLabelService =
           runtimeLabelService ?? const RuntimeLabelService();

  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RuntimeLabelService _runtimeLabelService;

  String build(
    ProjectDescriptor project, {
    ProjectRuntimeProfile? runtimeProfile,
  }) {
    // 中文注释: 工作台项目副标题统一从项目描述和运行画像投影，避免多个控制器各自拼接运行基准与存储文案。
    final segments = <String>[
      _projectTypeLabel(project.projectType),
      _runtimeLabelService.storageStrategyLabel(project.storageStrategy),
    ];
    final baselineId =
        (runtimeProfile?.runtimeBaselineId ?? project.runtimeBaselineId).trim();
    final runtimeMode = (runtimeProfile?.runtimeMode ?? '').trim();
    final baseline = _runtimeBaselineCatalogService.byId(baselineId);
    if (baseline != null) {
      segments.add(baseline.title);
    }
    if (runtimeMode.isNotEmpty &&
        _shouldExposeRuntimeMode(project.projectType)) {
      segments.add(_runtimeLabelService.runtimeModeLabel(runtimeMode));
    }
    return segments.where((item) => item.trim().isNotEmpty).join(' · ');
  }

  String _projectTypeLabel(String projectType) {
    switch (projectType.trim()) {
      case 'novel':
        return '普通小说项目';
      case 'long_novel':
        return '长篇项目';
      case 'knowledge_base':
        return '资料知识库';
      case 'short_collection':
      case 'short_story_collection':
        return '短篇集项目';
      case 'book_analysis':
      case 'book_deconstruction':
        return '拆书项目';
      default:
        return projectType.trim().isEmpty ? '项目' : projectType.trim();
    }
  }

  bool _shouldExposeRuntimeMode(String projectType) {
    switch (projectType.trim()) {
      case 'knowledge_base':
        return false;
      default:
        return true;
    }
  }
}
