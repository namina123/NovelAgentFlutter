class EcosystemImportCommandViewData {
  const EcosystemImportCommandViewData({
    required this.bundlePath,
    required this.overwrite,
    required this.allowBuiltinShadow,
    required this.status,
    required this.previewSummary,
  });

  final String bundlePath;
  final bool overwrite;
  final bool allowBuiltinShadow;
  final String status;
  final String previewSummary;

  EcosystemImportCommandViewData copyWith({
    String? bundlePath,
    bool? overwrite,
    bool? allowBuiltinShadow,
    String? status,
    String? previewSummary,
  }) {
    // 中文注释: 导入弹层状态采用局部 copy，避免控制器反复重建整份表单对象。
    return EcosystemImportCommandViewData(
      bundlePath: bundlePath ?? this.bundlePath,
      overwrite: overwrite ?? this.overwrite,
      allowBuiltinShadow: allowBuiltinShadow ?? this.allowBuiltinShadow,
      status: status ?? this.status,
      previewSummary: previewSummary ?? this.previewSummary,
    );
  }
}

class EcosystemImportRequestViewData {
  const EcosystemImportRequestViewData({
    required this.bundlePath,
    required this.overwrite,
    required this.allowBuiltinShadow,
  });

  final String bundlePath;
  final bool overwrite;
  final bool allowBuiltinShadow;
}
