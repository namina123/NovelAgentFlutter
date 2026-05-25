import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectAssetsSnapshot {
  const ProjectAssetsSnapshot({
    required this.activeTabId,
    required this.selectedStyleId,
    required this.selectedForeshadowId,
    required this.styles,
    required this.foreshadows,
  });

  final String activeTabId;
  final String selectedStyleId;
  final String selectedForeshadowId;
  final List<JsonMap> styles;
  final List<JsonMap> foreshadows;

  factory ProjectAssetsSnapshot.initial() {
    return const ProjectAssetsSnapshot(
      activeTabId: 'styles',
      selectedStyleId: '',
      selectedForeshadowId: '',
      styles: <JsonMap>[],
      foreshadows: <JsonMap>[],
    );
  }

  ProjectAssetsSnapshot copyWith({
    String? activeTabId,
    String? selectedStyleId,
    String? selectedForeshadowId,
    List<JsonMap>? styles,
    List<JsonMap>? foreshadows,
  }) {
    // 中文注释: 资产快照只保存原始数据与选中态，避免控制器直接维护表单投影细节。
    return ProjectAssetsSnapshot(
      activeTabId: activeTabId ?? this.activeTabId,
      selectedStyleId: selectedStyleId ?? this.selectedStyleId,
      selectedForeshadowId: selectedForeshadowId ?? this.selectedForeshadowId,
      styles: styles ?? this.styles,
      foreshadows: foreshadows ?? this.foreshadows,
    );
  }
}
