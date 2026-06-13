import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectInformationPermissionSettingsResolverService {
  const ProjectInformationPermissionSettingsResolverService();

  HostInformationPermissionContext resolveFromAppSettings(
    AppSettings settings, {
    String source = 'app_settings.permission_settings',
  }) {
    return resolve(
      settings.permissionSettings,
      source: source,
    );
  }

  HostInformationPermissionContext resolve(
    JsonMap permissionSettings, {
    String source = 'app_settings.permission_settings',
  }) {
    // 中文注释: adapter 薄桥只把宿主持久化设置翻译成 core 合同，不在这里读取文件系统或判断研究执行策略。
    final rawMode = _stringValue(
      permissionSettings['information_permission_mode'],
      _stringValue(permissionSettings['permission_mode'], _stringValue(permissionSettings['mode'])),
    ).toLowerCase();
    final permissionMode = _permissionMode(rawMode);
    final allowNetwork = _allowNetwork(permissionSettings, permissionMode);
    final allowImportCollection = _allowImportCollection(
      permissionSettings,
      permissionMode,
    );
    final confirmationMode = _confirmationMode(
      permissionSettings,
      permissionMode: permissionMode,
      allowNetwork: allowNetwork,
    );
    return HostInformationPermissionContext(
      allowNetwork: allowNetwork,
      allowImportCollection: allowImportCollection,
      permissionMode: permissionMode,
      confirmationMode: confirmationMode,
      source: source.trim().isEmpty
          ? 'app_settings.permission_settings'
          : source.trim(),
      metadata: <String, Object?>{
        'raw_permission_settings': Map<String, Object?>.from(permissionSettings),
        'raw_mode': rawMode,
        'resolved_from': 'project_information_permission_settings_resolver_service',
        'settings_allow_network': _boolValue(permissionSettings['allow_network']),
        'settings_allow_read': _boolValue(permissionSettings['allow_read']),
        'settings_allow_write': _boolValue(permissionSettings['allow_write']),
        'settings_allow_delete': _boolValue(permissionSettings['allow_delete']),
        'settings_allow_process': _boolValue(permissionSettings['allow_process']),
      },
    );
  }

  String _permissionMode(String rawMode) {
    switch (rawMode) {
      case 'all':
      case 'open':
        return HostInformationPermissionModes.open;
      case 'safe':
        return HostInformationPermissionModes.safe;
      case 'import_only':
        return HostInformationPermissionModes.importOnly;
      case 'custom':
        return HostInformationPermissionModes.custom;
      case '':
        return HostInformationPermissionModes.safe;
      default:
        return HostInformationPermissionModes.knownValues.contains(rawMode)
            ? rawMode
            : HostInformationPermissionModes.unknown;
    }
  }

  bool _allowNetwork(JsonMap permissionSettings, String permissionMode) {
    if (permissionSettings.containsKey('allow_network')) {
      return _boolValue(permissionSettings['allow_network']);
    }
    return permissionMode == HostInformationPermissionModes.open;
  }

  bool _allowImportCollection(
    JsonMap permissionSettings,
    String permissionMode,
  ) {
    if (permissionSettings.containsKey('allow_import_collection')) {
      return _boolValue(permissionSettings['allow_import_collection']);
    }
    switch (permissionMode) {
      case HostInformationPermissionModes.open:
      case HostInformationPermissionModes.safe:
      case HostInformationPermissionModes.importOnly:
        return true;
      case HostInformationPermissionModes.custom:
        return _boolValue(permissionSettings['allow_read']) &&
            _boolValue(permissionSettings['allow_write']);
      default:
        return true;
    }
  }

  String _confirmationMode(
    JsonMap permissionSettings, {
    required String permissionMode,
    required bool allowNetwork,
  }) {
    final explicit = _stringValue(
      permissionSettings['information_confirmation_mode'],
      _stringValue(permissionSettings['confirmation_mode']),
    ).toLowerCase();
    if (HostInformationConfirmationModes.knownValues.contains(explicit)) {
      return explicit;
    }
    switch (permissionMode) {
      case HostInformationPermissionModes.open:
      case HostInformationPermissionModes.importOnly:
        return HostInformationConfirmationModes.automatic;
      case HostInformationPermissionModes.custom:
        return allowNetwork
            ? HostInformationConfirmationModes.automatic
            : HostInformationConfirmationModes.userConfirmationRequired;
      case HostInformationPermissionModes.unknown:
        return allowNetwork
            ? HostInformationConfirmationModes.unknown
            : HostInformationConfirmationModes.userConfirmationRequired;
      case HostInformationPermissionModes.safe:
      default:
        return HostInformationConfirmationModes.userConfirmationRequired;
    }
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _boolValue(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
  }
}
