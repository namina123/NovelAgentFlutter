import '../models/model_editor_view_data.dart';

abstract class SettingsActionHandler {
  void onSettingsBackRequested();

  void onSettingsTabSelected(String tabId);

  void onProviderSelected(String providerId);

  void onProviderCreateRequested();

  void onProviderDetailBackRequested();

  void onProviderSaved(Map<String, Object?> payload);

  void onProviderDeleted(String providerId);

  /// 中文注释: 连接测试在「模型」页发起，使用当前选中的"接口 + 模型"真实配对；
  /// 返回本地自检 + 联网探测合并后的结果，供模型页直接展示，不再回灌接口页。
  Future<ProviderConnectionValidationResultViewData>
  onModelConnectionTestRequested(Map<String, Object?> payload);

  void onModelSettingsSaved(Map<String, Object?> payload);

  void onPermissionSettingsSaved(Map<String, Object?> payload);

  void onToolStrategySettingsSaved(Map<String, Object?> payload);

  void onProjectCreationExpressionConstraintDefaultsSaved(
    Map<String, Object?> payload,
  );

  void onNetworkSettingsSaved(Map<String, Object?> payload);

  void onContextSettingsSaved(Map<String, Object?> payload);

  void onThemeSettingsSaved(Map<String, Object?> payload);
}
