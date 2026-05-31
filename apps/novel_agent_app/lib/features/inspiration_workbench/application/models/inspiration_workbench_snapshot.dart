import 'package:novel_agent_core/novel_agent_core.dart';

class InspirationWorkbenchSnapshot {
  const InspirationWorkbenchSnapshot({
    required this.isLoading,
    required this.projectType,
    required this.availableModes,
    required this.selectedModeId,
    required this.selectedStageId,
    required this.state,
    required this.assetBundle,
    required this.projectedDocuments,
  });

  final bool isLoading;
  final String projectType;
  final List<ModeDefinition> availableModes;
  final String selectedModeId;
  final String selectedStageId;
  final ModeGuidanceState? state;
  final ModeGuidanceAssetBundle? assetBundle;
  final Map<String, String> projectedDocuments;

  factory InspirationWorkbenchSnapshot.initial() {
    return const InspirationWorkbenchSnapshot(
      isLoading: false,
      projectType: '',
      availableModes: <ModeDefinition>[],
      selectedModeId: '',
      selectedStageId: '',
      state: null,
      assetBundle: null,
      projectedDocuments: <String, String>{},
    );
  }

  InspirationWorkbenchSnapshot copyWith({
    bool? isLoading,
    String? projectType,
    List<ModeDefinition>? availableModes,
    String? selectedModeId,
    String? selectedStageId,
    Object? state = _stateSentinel,
    Object? assetBundle = _assetBundleSentinel,
    Map<String, String>? projectedDocuments,
  }) {
    // 中文注释: 灵感工作台快照只承载页面真正需要的共享状态，不把临时输入控件状态塞进来。
    return InspirationWorkbenchSnapshot(
      isLoading: isLoading ?? this.isLoading,
      projectType: projectType ?? this.projectType,
      availableModes: availableModes ?? this.availableModes,
      selectedModeId: selectedModeId ?? this.selectedModeId,
      selectedStageId: selectedStageId ?? this.selectedStageId,
      state: identical(state, _stateSentinel)
          ? this.state
          : state as ModeGuidanceState?,
      assetBundle: identical(assetBundle, _assetBundleSentinel)
          ? this.assetBundle
          : assetBundle as ModeGuidanceAssetBundle?,
      projectedDocuments: projectedDocuments ?? this.projectedDocuments,
    );
  }
}

const Object _stateSentinel = Object();
const Object _assetBundleSentinel = Object();
