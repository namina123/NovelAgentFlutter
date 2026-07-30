class EcosystemImportCommandViewData {
  const EcosystemImportCommandViewData({
    required this.bundlePath,
    required this.overwrite,
    required this.allowBuiltinShadow,
    required this.status,
    required this.previewSummary,
    this.isImporting = false,
  });

  final String bundlePath;
  final bool overwrite;
  final bool allowBuiltinShadow;
  final String status;
  final String previewSummary;
  /// 中文注释: 导入进行中标志——真联网预检+写入期间为 true，弹层据此禁用提交按钮，
  /// 避免慢盘/网络下用户连点触发并行导入写同一批文件。
  final bool isImporting;

  EcosystemImportCommandViewData copyWith({
    String? bundlePath,
    bool? overwrite,
    bool? allowBuiltinShadow,
    String? status,
    String? previewSummary,
    bool? isImporting,
  }) {
    // 中文注释: 导入弹层状态采用局部 copy，避免控制器反复重建整份表单对象。
    return EcosystemImportCommandViewData(
      bundlePath: bundlePath ?? this.bundlePath,
      overwrite: overwrite ?? this.overwrite,
      allowBuiltinShadow: allowBuiltinShadow ?? this.allowBuiltinShadow,
      status: status ?? this.status,
      previewSummary: previewSummary ?? this.previewSummary,
      isImporting: isImporting ?? this.isImporting,
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
