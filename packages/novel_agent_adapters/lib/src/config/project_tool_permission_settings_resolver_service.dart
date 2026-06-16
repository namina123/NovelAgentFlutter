import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectToolPermissionSettingsResolverService {
  const ProjectToolPermissionSettingsResolverService();

  HostToolPermissionContext resolveFromAppSettings(
    AppSettings settings, {
    String source = 'app_settings.permission_settings',
  }) {
    return resolve(settings.permissionSettings, source: source);
  }

  HostToolPermissionContext resolve(
    JsonMap permissionSettings, {
    String source = 'app_settings.permission_settings',
  }) {
    final rawMode = _stringValue(
      permissionSettings['tool_permission_mode'],
      _stringValue(
        permissionSettings['permission_mode'],
        _stringValue(permissionSettings['mode']),
      ),
    ).toLowerCase();
    final permissionMode = _permissionMode(rawMode);
    final allowRead = _resolvedFlag(
      permissionSettings,
      key: 'allow_read',
      fallback: switch (permissionMode) {
        HostToolPermissionModes.open => true,
        HostToolPermissionModes.safe => true,
        HostToolPermissionModes.importOnly => true,
        _ => false,
      },
    );
    final allowWrite = _resolvedFlag(
      permissionSettings,
      key: 'allow_write',
      fallback: switch (permissionMode) {
        HostToolPermissionModes.open => true,
        HostToolPermissionModes.safe => true,
        _ => false,
      },
    );
    final allowDelete = _resolvedFlag(
      permissionSettings,
      key: 'allow_delete',
      fallback: permissionMode == HostToolPermissionModes.open,
    );
    final allowNetwork = _resolvedFlag(
      permissionSettings,
      key: 'allow_network',
      fallback: permissionMode == HostToolPermissionModes.open,
    );
    final allowProcess = _resolvedFlag(
      permissionSettings,
      key: 'allow_process',
      fallback: permissionMode == HostToolPermissionModes.open,
    );
    final allowSubAgents = _resolvedFlag(
      permissionSettings,
      key: 'allow_sub_agents',
      fallback: switch (permissionMode) {
        HostToolPermissionModes.open => true,
        HostToolPermissionModes.safe => true,
        _ => false,
      },
    );
    final allowLongTaskControl = _resolvedFlag(
      permissionSettings,
      key: 'allow_long_task_control',
      fallback: switch (permissionMode) {
        HostToolPermissionModes.open => true,
        HostToolPermissionModes.safe => true,
        _ => false,
      },
    );
    final allowFormalDelivery = _resolvedFlag(
      permissionSettings,
      key: 'allow_formal_delivery',
      fallback: switch (permissionMode) {
        HostToolPermissionModes.open => true,
        HostToolPermissionModes.safe => true,
        _ => false,
      },
    );
    final confirmationMode = _confirmationMode(
      permissionSettings,
      permissionMode: permissionMode,
    );
    return HostToolPermissionContext(
      allowRead: allowRead,
      allowWrite: allowWrite,
      allowDelete: allowDelete,
      allowNetwork: allowNetwork,
      allowProcess: allowProcess,
      allowSubAgents: allowSubAgents,
      allowLongTaskControl: allowLongTaskControl,
      allowFormalDelivery: allowFormalDelivery,
      permissionMode: permissionMode,
      confirmationMode: confirmationMode,
      source: source.trim().isEmpty
          ? 'app_settings.permission_settings'
          : source.trim(),
      metadata: <String, Object?>{
        'raw_permission_settings': Map<String, Object?>.from(
          permissionSettings,
        ),
        'raw_mode': rawMode,
        'resolved_from': 'project_tool_permission_settings_resolver_service',
      },
    );
  }

  String _permissionMode(String rawMode) {
    switch (rawMode) {
      case 'all':
      case 'open':
        return HostToolPermissionModes.open;
      case 'safe':
        return HostToolPermissionModes.safe;
      case 'import_only':
        return HostToolPermissionModes.importOnly;
      case 'custom':
        return HostToolPermissionModes.custom;
      case '':
        return HostToolPermissionModes.safe;
      default:
        return HostToolPermissionModes.knownValues.contains(rawMode)
            ? rawMode
            : HostToolPermissionModes.unknown;
    }
  }

  String _confirmationMode(
    JsonMap permissionSettings, {
    required String permissionMode,
  }) {
    final explicit = _stringValue(
      permissionSettings['tool_confirmation_mode'],
      _stringValue(
        permissionSettings['confirmation_mode'],
        _stringValue(permissionSettings['information_confirmation_mode']),
      ),
    ).toLowerCase();
    if (HostToolConfirmationModes.knownValues.contains(explicit)) {
      return explicit;
    }
    switch (permissionMode) {
      case HostToolPermissionModes.open:
        return HostToolConfirmationModes.automatic;
      case HostToolPermissionModes.importOnly:
      case HostToolPermissionModes.safe:
      case HostToolPermissionModes.custom:
      case HostToolPermissionModes.unknown:
      default:
        return HostToolConfirmationModes.userConfirmationRequired;
    }
  }

  bool _resolvedFlag(
    JsonMap permissionSettings, {
    required String key,
    required bool fallback,
  }) {
    if (permissionSettings.containsKey(key)) {
      return _boolValue(permissionSettings[key]);
    }
    return fallback;
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
