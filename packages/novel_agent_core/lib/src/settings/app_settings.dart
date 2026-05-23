import '../common/json_types.dart';
import 'provider_endpoint_settings.dart';

class AppSettings {
  const AppSettings({
    required this.defaultProviderId,
    required this.defaultAgentId,
    required this.defaultModelId,
    required this.defaultProjectPath,
    required this.autoSaveDrafts,
    required this.providers,
    this.permissionSettings = const <String, Object?>{},
    this.toolStrategySettings = const <String, Object?>{},
    this.networkSettings = const <String, Object?>{},
    this.contextSettings = const <String, Object?>{},
    this.themeSettings = const <String, Object?>{},
    this.extraSettings = const <String, Object?>{},
  });

  final String defaultProviderId;
  final String defaultAgentId;
  final String defaultModelId;
  final String defaultProjectPath;
  final bool autoSaveDrafts;
  final List<ProviderEndpointSettings> providers;
  final JsonMap permissionSettings;
  final JsonMap toolStrategySettings;
  final JsonMap networkSettings;
  final JsonMap contextSettings;
  final JsonMap themeSettings;
  final JsonMap extraSettings;

  ProviderEndpointSettings? defaultProvider() {
    // 中文注释: 默认 provider 解析集中放在设置模型里，避免 GUI 和 CLI 各自重复挑选逻辑。
    if (providers.isEmpty) {
      return null;
    }
    for (final provider in providers) {
      if (provider.id == defaultProviderId) {
        return provider;
      }
    }
    for (final provider in providers) {
      if (provider.isDefault) {
        return provider;
      }
    }
    return providers.first;
  }

  AppSettings copyWith({
    String? defaultProviderId,
    String? defaultAgentId,
    String? defaultModelId,
    String? defaultProjectPath,
    bool? autoSaveDrafts,
    List<ProviderEndpointSettings>? providers,
    JsonMap? permissionSettings,
    JsonMap? toolStrategySettings,
    JsonMap? networkSettings,
    JsonMap? contextSettings,
    JsonMap? themeSettings,
    JsonMap? extraSettings,
  }) {
    // 中文注释: 应用设置通过 copyWith 复制更新，方便控制器按页签分步提交而不丢失其他设置段。
    return AppSettings(
      defaultProviderId: defaultProviderId ?? this.defaultProviderId,
      defaultAgentId: defaultAgentId ?? this.defaultAgentId,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      defaultProjectPath: defaultProjectPath ?? this.defaultProjectPath,
      autoSaveDrafts: autoSaveDrafts ?? this.autoSaveDrafts,
      providers: providers ?? this.providers,
      permissionSettings: permissionSettings ?? this.permissionSettings,
      toolStrategySettings: toolStrategySettings ?? this.toolStrategySettings,
      networkSettings: networkSettings ?? this.networkSettings,
      contextSettings: contextSettings ?? this.contextSettings,
      themeSettings: themeSettings ?? this.themeSettings,
      extraSettings: extraSettings ?? this.extraSettings,
    );
  }
}
