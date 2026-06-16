import 'model_editor_view_data.dart';
import 'project_creation_expression_constraint_defaults_view_data.dart';
import 'theme_settings_view_data.dart';

class SettingsViewData {
  const SettingsViewData({
    required this.activeTabId,
    required this.tabs,
    required this.providers,
    required this.providerDirectoryOptions,
    required this.allModelOptions,
    required this.tabSections,
    required this.defaultProviderId,
    required this.defaultModelId,
    required this.modelSettings,
    required this.modelEditor,
    required this.defaultProjectPath,
    this.draftFallbackProtectionEnabled = true,
    required this.permissionSettings,
    required this.toolStrategySettings,
    required this.projectCreationExpressionConstraintDefaults,
    required this.networkSettings,
    required this.contextSettings,
    required this.themeSettings,
    required this.themeViewData,
    required this.settingsRootPath,
    required this.settingsSearchRoots,
    required this.defaultProjectsRootPath,
    required this.isMobileProjectRootLocked,
  });

  final String activeTabId;
  final List<SettingsTabViewData> tabs;
  final List<ProviderEndpointViewData> providers;
  final List<ProviderDirectoryOptionViewData> providerDirectoryOptions;
  final List<SettingsSearchOptionViewData> allModelOptions;
  final Map<String, List<SettingsSectionViewData>> tabSections;
  final String defaultProviderId;
  final String defaultModelId;
  final Map<String, Object?> modelSettings;
  final ModelEditorViewData modelEditor;
  final String defaultProjectPath;
  final bool draftFallbackProtectionEnabled;
  final Map<String, Object?> permissionSettings;
  final Map<String, Object?> toolStrategySettings;
  final ProjectCreationExpressionConstraintDefaultsViewData
  projectCreationExpressionConstraintDefaults;
  final Map<String, Object?> networkSettings;
  final Map<String, Object?> contextSettings;
  final Map<String, Object?> themeSettings;
  final ThemeSettingsViewData themeViewData;
  final String settingsRootPath;
  final List<String> settingsSearchRoots;
  final String defaultProjectsRootPath;
  final bool isMobileProjectRootLocked;

  factory SettingsViewData.initial() {
    return SettingsViewData(
      activeTabId: 'interfaces',
      tabs: [
        SettingsTabViewData(id: 'interfaces', label: '接口'),
        SettingsTabViewData(id: 'models', label: '模型'),
        SettingsTabViewData(id: 'permissions', label: '权限'),
        SettingsTabViewData(id: 'tooling', label: '工具策略'),
        SettingsTabViewData(id: 'network', label: '网络'),
        SettingsTabViewData(id: 'context', label: '上下文'),
        SettingsTabViewData(id: 'theme', label: '主题'),
      ],
      providers: [],
      providerDirectoryOptions: [],
      allModelOptions: [],
      tabSections: <String, List<SettingsSectionViewData>>{},
      defaultProviderId: '',
      defaultModelId: '',
      modelSettings: <String, Object?>{},
      modelEditor: ModelEditorViewData.initial,
      defaultProjectPath: '',
      draftFallbackProtectionEnabled: true,
      permissionSettings: <String, Object?>{},
      toolStrategySettings: <String, Object?>{},
      projectCreationExpressionConstraintDefaults:
          ProjectCreationExpressionConstraintDefaultsViewData.initial(),
      networkSettings: <String, Object?>{},
      contextSettings: <String, Object?>{},
      themeSettings: <String, Object?>{},
      themeViewData: ThemeSettingsViewData.initial(),
      settingsRootPath: '',
      settingsSearchRoots: <String>[],
      defaultProjectsRootPath: '',
      isMobileProjectRootLocked: false,
    );
  }

  factory SettingsViewData.demo() {
    return SettingsViewData.initial();
  }

  SettingsViewData copyWith({
    String? activeTabId,
    List<SettingsTabViewData>? tabs,
    List<ProviderEndpointViewData>? providers,
    List<ProviderDirectoryOptionViewData>? providerDirectoryOptions,
    List<SettingsSearchOptionViewData>? allModelOptions,
    Map<String, List<SettingsSectionViewData>>? tabSections,
    String? defaultProviderId,
    String? defaultModelId,
    Map<String, Object?>? modelSettings,
    ModelEditorViewData? modelEditor,
    String? defaultProjectPath,
    bool? draftFallbackProtectionEnabled,
    Map<String, Object?>? permissionSettings,
    Map<String, Object?>? toolStrategySettings,
    ProjectCreationExpressionConstraintDefaultsViewData?
    projectCreationExpressionConstraintDefaults,
    Map<String, Object?>? networkSettings,
    Map<String, Object?>? contextSettings,
    Map<String, Object?>? themeSettings,
    ThemeSettingsViewData? themeViewData,
    String? settingsRootPath,
    List<String>? settingsSearchRoots,
    String? defaultProjectsRootPath,
    bool? isMobileProjectRootLocked,
  }) {
    // 中文注释: 设置状态通过局部 copy 维持稳定引用边界，避免 tab 切换把整页对象全部推翻重建。
    return SettingsViewData(
      activeTabId: activeTabId ?? this.activeTabId,
      tabs: tabs ?? this.tabs,
      providers: providers ?? this.providers,
      providerDirectoryOptions:
          providerDirectoryOptions ?? this.providerDirectoryOptions,
      allModelOptions: allModelOptions ?? this.allModelOptions,
      tabSections: tabSections ?? this.tabSections,
      defaultProviderId: defaultProviderId ?? this.defaultProviderId,
      defaultModelId: defaultModelId ?? this.defaultModelId,
      modelSettings: modelSettings ?? this.modelSettings,
      modelEditor: modelEditor ?? this.modelEditor,
      defaultProjectPath: defaultProjectPath ?? this.defaultProjectPath,
      draftFallbackProtectionEnabled:
          draftFallbackProtectionEnabled ?? this.draftFallbackProtectionEnabled,
      permissionSettings: permissionSettings ?? this.permissionSettings,
      toolStrategySettings: toolStrategySettings ?? this.toolStrategySettings,
      projectCreationExpressionConstraintDefaults:
          projectCreationExpressionConstraintDefaults ??
          this.projectCreationExpressionConstraintDefaults,
      networkSettings: networkSettings ?? this.networkSettings,
      contextSettings: contextSettings ?? this.contextSettings,
      themeSettings: themeSettings ?? this.themeSettings,
      themeViewData: themeViewData ?? this.themeViewData,
      settingsRootPath: settingsRootPath ?? this.settingsRootPath,
      settingsSearchRoots: settingsSearchRoots ?? this.settingsSearchRoots,
      defaultProjectsRootPath:
          defaultProjectsRootPath ?? this.defaultProjectsRootPath,
      isMobileProjectRootLocked:
          isMobileProjectRootLocked ?? this.isMobileProjectRootLocked,
    );
  }
}

class SettingsTabViewData {
  const SettingsTabViewData({required this.id, required this.label});

  final String id;
  final String label;
}

class ProviderEndpointViewData {
  const ProviderEndpointViewData({
    required this.id,
    required this.title,
    required this.protocol,
    required this.baseUrl,
    required this.rawApiKey,
    required this.apiKeyState,
    required this.description,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final String protocol;
  final String baseUrl;
  final String rawApiKey;
  final String apiKeyState;
  final String description;
  final bool isSelected;
}

class ProviderDraftViewData {
  const ProviderDraftViewData({
    required this.title,
    required this.protocol,
    required this.baseUrl,
    required this.apiKey,
    required this.description,
    required this.modelId,
    this.selectedDirectoryProviderId,
  });

  final String title;
  final String protocol;
  final String baseUrl;
  final String apiKey;
  final String description;
  final String modelId;
  final String? selectedDirectoryProviderId;
}

class ProviderDirectoryOptionViewData {
  const ProviderDirectoryOptionViewData({
    required this.id,
    required this.label,
    required this.protocol,
    required this.defaultBaseUrl,
  });

  final String id;
  final String label;
  final String protocol;
  final String defaultBaseUrl;
}

class SettingsSearchOptionViewData {
  const SettingsSearchOptionViewData({
    required this.value,
    required this.label,
    this.note = '',
  });

  final String value;
  final String label;
  final String note;
}

class SettingsSectionViewData {
  const SettingsSectionViewData({
    required this.title,
    required this.items,
    this.description = '',
  });

  final String title;
  final String description;
  final List<SettingsItemViewData> items;
}

class SettingsItemViewData {
  const SettingsItemViewData({required this.label, required this.value});

  final String label;
  final String value;
}
