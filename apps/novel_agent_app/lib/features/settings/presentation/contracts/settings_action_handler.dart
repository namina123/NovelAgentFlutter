abstract class SettingsActionHandler {
  void onSettingsBackRequested();

  void onSettingsTabSelected(String tabId);

  void onProviderSelected(String providerId);

  void onProviderCreateRequested();

  void onProviderDetailBackRequested();

  void onProviderSaved(Map<String, Object?> payload);

  void onProviderDeleted(String providerId);

  void onModelSettingsSaved(Map<String, Object?> payload);

  void onPermissionSettingsSaved(Map<String, Object?> payload);

  void onToolStrategySettingsSaved(Map<String, Object?> payload);

  void onNetworkSettingsSaved(Map<String, Object?> payload);

  void onContextSettingsSaved(Map<String, Object?> payload);

  void onThemeSettingsSaved(Map<String, Object?> payload);
}
