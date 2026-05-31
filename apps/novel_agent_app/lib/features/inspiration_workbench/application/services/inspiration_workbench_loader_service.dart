import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/inspiration_workbench_snapshot.dart';

class InspirationWorkbenchLoaderService {
  InspirationWorkbenchLoaderService({
    LoadModeGuidanceStateUseCase? loadModeGuidanceStateUseCase,
    StrategyCatalogService? strategyCatalogService,
    ModeGuidanceAssetBundleBuilderService? assetBundleBuilderService,
    ModeGuidanceProjectionDocumentService? projectionDocumentService,
  }) : _loadModeGuidanceStateUseCase =
           loadModeGuidanceStateUseCase ??
           LoadModeGuidanceStateUseCase(statePort: _UnsupportedStatePort()),
       _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService(),
       _assetBundleBuilderService =
           assetBundleBuilderService ??
           const ModeGuidanceAssetBundleBuilderService(),
       _projectionDocumentService =
           projectionDocumentService ??
           const ModeGuidanceProjectionDocumentService();

  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final StrategyCatalogService _strategyCatalogService;
  final ModeGuidanceAssetBundleBuilderService _assetBundleBuilderService;
  final ModeGuidanceProjectionDocumentService _projectionDocumentService;

  List<ModeDefinition> supportedModes() {
    // 中文注释: 当前工作台只暴露已经具备完整引导阶段的模式，避免半成品模式误进共享入口。
    return _strategyCatalogService
        .modeDefinitions()
        .where((definition) => definition.stages.isNotEmpty)
        .toList(growable: false);
  }

  Future<InspirationWorkbenchSnapshot> load(
    ProjectDescriptor project, {
    required String modeId,
    required String selectedStageId,
  }) async {
    // 中文注释: 读侧统一从共享 mode guidance 状态恢复，再投影为灵感资产预览，避免 GUI 自己拼状态。
    final modes = supportedModes();
    final resolvedMode = _resolveModeId(modes, modeId);
    final state = await _loadModeGuidanceStateUseCase.execute(
      project,
      modeId: resolvedMode,
    );
    final assetBundle = _assetBundleBuilderService.build(state);
    final documents = _projectionDocumentService.buildDocuments(state);
    return InspirationWorkbenchSnapshot(
      isLoading: false,
      projectType: project.projectType,
      availableModes: modes,
      selectedModeId: resolvedMode,
      selectedStageId: _resolveStageId(
        modes: modes,
        modeId: resolvedMode,
        state: state,
        selectedStageId: selectedStageId,
      ),
      state: state,
      assetBundle: assetBundle,
      projectedDocuments: documents,
    );
  }

  String resolveDefaultModeId(String currentModeId) {
    final modes = supportedModes();
    return _resolveModeId(modes, currentModeId);
  }

  String resolveStageId(InspirationWorkbenchSnapshot snapshot) {
    return _resolveStageId(
      modes: snapshot.availableModes,
      modeId: snapshot.selectedModeId,
      state: snapshot.state,
      selectedStageId: snapshot.selectedStageId,
    );
  }

  String _resolveModeId(List<ModeDefinition> modes, String modeId) {
    final cleanModeId = modeId.trim();
    for (final definition in modes) {
      if (definition.id == cleanModeId) {
        return cleanModeId;
      }
    }
    return modes.isEmpty ? '' : modes.first.id;
  }

  String _resolveStageId({
    required List<ModeDefinition> modes,
    required String modeId,
    required ModeGuidanceState? state,
    required String selectedStageId,
  }) {
    final definition = _definitionOf(modes, modeId);
    if (definition == null || definition.stages.isEmpty) {
      return '';
    }
    final cleanSelectedStageId = selectedStageId.trim();
    for (final stage in definition.stages) {
      if (stage.id == cleanSelectedStageId) {
        return cleanSelectedStageId;
      }
    }
    final stateStageId = state?.currentStageId.trim() ?? '';
    for (final stage in definition.stages) {
      if (stage.id == stateStageId) {
        return stateStageId;
      }
    }
    return definition.stages.first.id;
  }

  ModeDefinition? _definitionOf(List<ModeDefinition> modes, String modeId) {
    for (final definition in modes) {
      if (definition.id == modeId.trim()) {
        return definition;
      }
    }
    return null;
  }
}

class _UnsupportedStatePort implements ModeGuidanceStatePort {
  @override
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  }) {
    throw UnimplementedError('This placeholder state port should not be used.');
  }

  @override
  Future<void> save(ProjectDescriptor project, ModeGuidanceState state) {
    throw UnimplementedError('This placeholder state port should not be used.');
  }
}
