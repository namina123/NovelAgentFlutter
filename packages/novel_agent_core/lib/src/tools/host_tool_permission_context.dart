import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';

const _hostToolPermissionContextCodecService = OpenJsonContractCodecService();
const _hostToolPermissionContextValidatorService =
    OpenJsonStructureValidatorService();
const _hostToolPermissionContextKnownFields = <String>{
  'allow_read',
  'allow_write',
  'allow_delete',
  'allow_network',
  'allow_process',
  'allow_sub_agents',
  'allow_long_task_control',
  'allow_formal_delivery',
  'permission_mode',
  'confirmation_mode',
  'source',
  'metadata',
};

abstract final class HostToolPermissionModes {
  static const String open = 'open';
  static const String safe = 'safe';
  static const String importOnly = 'import_only';
  static const String custom = 'custom';
  static const String unknown = 'unknown';

  static const List<String> knownValues = <String>[
    open,
    safe,
    importOnly,
    custom,
    unknown,
  ];
}

abstract final class HostToolConfirmationModes {
  static const String automatic = 'automatic';
  static const String userConfirmationRequired = 'user_confirmation_required';
  static const String never = 'never';
  static const String unknown = 'unknown';

  static const List<String> knownValues = <String>[
    automatic,
    userConfirmationRequired,
    never,
    unknown,
  ];
}

class HostToolPermissionContext {
  const HostToolPermissionContext({
    this.allowRead = false,
    this.allowWrite = false,
    this.allowDelete = false,
    this.allowNetwork = false,
    this.allowProcess = false,
    this.allowSubAgents = false,
    this.allowLongTaskControl = false,
    this.allowFormalDelivery = false,
    this.permissionMode = '',
    this.confirmationMode = '',
    this.source = '',
    this.metadata = const <String, Object?>{},
  });

  final bool allowRead;
  final bool allowWrite;
  final bool allowDelete;
  final bool allowNetwork;
  final bool allowProcess;
  final bool allowSubAgents;
  final bool allowLongTaskControl;
  final bool allowFormalDelivery;
  final String permissionMode;
  final String confirmationMode;
  final String source;
  final JsonMap metadata;

  HostToolPermissionContext copyWith({
    bool? allowRead,
    bool? allowWrite,
    bool? allowDelete,
    bool? allowNetwork,
    bool? allowProcess,
    bool? allowSubAgents,
    bool? allowLongTaskControl,
    bool? allowFormalDelivery,
    String? permissionMode,
    String? confirmationMode,
    String? source,
    JsonMap? metadata,
  }) {
    return HostToolPermissionContext(
      allowRead: allowRead ?? this.allowRead,
      allowWrite: allowWrite ?? this.allowWrite,
      allowDelete: allowDelete ?? this.allowDelete,
      allowNetwork: allowNetwork ?? this.allowNetwork,
      allowProcess: allowProcess ?? this.allowProcess,
      allowSubAgents: allowSubAgents ?? this.allowSubAgents,
      allowLongTaskControl: allowLongTaskControl ?? this.allowLongTaskControl,
      allowFormalDelivery: allowFormalDelivery ?? this.allowFormalDelivery,
      permissionMode: permissionMode ?? this.permissionMode,
      confirmationMode: confirmationMode ?? this.confirmationMode,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  factory HostToolPermissionContext.fromJson(JsonMap json) {
    return HostToolPermissionContext(
      allowRead: ValueReaders.boolValue(json['allow_read']),
      allowWrite: ValueReaders.boolValue(json['allow_write']),
      allowDelete: ValueReaders.boolValue(json['allow_delete']),
      allowNetwork: ValueReaders.boolValue(json['allow_network']),
      allowProcess: ValueReaders.boolValue(json['allow_process']),
      allowSubAgents: ValueReaders.boolValue(json['allow_sub_agents']),
      allowLongTaskControl: ValueReaders.boolValue(
        json['allow_long_task_control'],
      ),
      allowFormalDelivery: ValueReaders.boolValue(
        json['allow_formal_delivery'],
      ),
      permissionMode: ValueReaders.stringValue(json['permission_mode']).trim(),
      confirmationMode: ValueReaders.stringValue(
        json['confirmation_mode'],
      ).trim(),
      source: ValueReaders.stringValue(json['source']).trim(),
      metadata: _hostToolPermissionContextCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _hostToolPermissionContextKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _hostToolPermissionContextCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'allow_read': allowRead,
          'allow_write': allowWrite,
          'allow_delete': allowDelete,
          'allow_network': allowNetwork,
          'allow_process': allowProcess,
          'allow_sub_agents': allowSubAgents,
          'allow_long_task_control': allowLongTaskControl,
          'allow_formal_delivery': allowFormalDelivery,
          'permission_mode': permissionMode,
          'confirmation_mode': confirmationMode,
          'source': source,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _hostToolPermissionContextValidatorService.requireNonBlankString(
        permissionMode,
        'missing_host_tool_permission_mode',
      ),
    );
    result.addAll(
      _hostToolPermissionContextValidatorService.requireNonBlankString(
        confirmationMode,
        'missing_host_tool_confirmation_mode',
      ),
    );
    result.addAll(
      _hostToolPermissionContextValidatorService.requireNonBlankString(
        source,
        'missing_host_tool_permission_source',
      ),
    );
    return result;
  }
}
