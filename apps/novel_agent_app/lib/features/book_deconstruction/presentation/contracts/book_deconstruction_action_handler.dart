abstract class BookDeconstructionActionHandler {
  void onBookDeconstructionBackRequested();

  void onBookDeconstructionRefreshRequested();

  void onBookDeconstructionStepSelected(String stepId);

  void onBookDeconstructionCancelRequested();

  // 步骤①：导入（单一入口：文件选择；移动端走粘贴框兜底）。
  Future<void> onBookDeconstructionImportFileRequested();

  void onBookDeconstructionSourceTitleChanged(String value);

  void onBookDeconstructionSourceContentChanged(String value);

  // 步骤②：拆书（纯净分章）。可选勾"使用模型"并选模型（未选模型不能勾）；
  // 无论是否用模型，都只产出纯净分章正文。
  void onBookDeconstructionSplitUseModelChanged(bool value);

  void onBookDeconstructionSplitModelSelected(String optionKey);

  Future<void> onBookDeconstructionSplitRequested();

  // 步骤③：分析（可选·需选模型；模型与拆书独立不继承；不选模型则不分析）。
  void onBookDeconstructionAnalysisUseModelChanged(bool value);

  void onBookDeconstructionAnalysisModelSelected(String optionKey);

  Future<void> onBookDeconstructionAnalysisRequested();

  // 步骤④：确认。
  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  });

  void onBookDeconstructionSelectAllRequested();

  void onBookDeconstructionClearSelectionRequested();

  void onBookDeconstructionFollowupOptionSelected(String optionId);

  // 步骤④：复合项目类型——选目标写作类型 + 续写开关（分章是否作为正文基础写入 chapters/）。
  void onBookDeconstructionTargetWritingTypeSelected(
    String targetWritingTypeId,
  );

  void onBookDeconstructionTargetRuntimeBaselineSelected(
    String runtimeBaselineId,
  );

  void onBookDeconstructionInheritAsLiveNarrativeChanged(bool value);

  /// Applies the exact staged package from step ③ only when the user opts in
  /// during confirmation. The default remains false.
  void onBookDeconstructionApplyStagedAnalysisResultsChanged(bool value);

  Future<void> onBookDeconstructionConfirmRequested();

  Future<void> onBookDeconstructionCreateDerivedProjectRequested();
}
