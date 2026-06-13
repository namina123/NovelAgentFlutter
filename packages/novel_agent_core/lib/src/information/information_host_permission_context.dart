import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'information_validation_codes.dart';

const _hostInformationPermissionContextCodecService =
    OpenJsonContractCodecService();
const _hostInformationPermissionContextValidatorService =
    OpenJsonStructureValidatorService();
const _hostInformationPermissionContextKnownFields = <String>{
  'allow_network',
  'allow_import_collection',
  'permission_mode',
  'confirmation_mode',
  'source',
  'metadata',
};

abstract final class HostInformationPermissionModes {
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

abstract final class HostInformationConfirmationModes {
  static const String automatic = 'automatic';
  static const String userConfirmationRequired =
      'user_confirmation_required';
  static const String never = 'never';
  static const String unknown = 'unknown';

  static const List<String> knownValues = <String>[
    automatic,
    userConfirmationRequired,
    never,
    unknown,
  ];
}

class HostInformationPermissionContext {
  const HostInformationPermissionContext({
    this.allowNetwork = false,
    this.allowImportCollection = false,
    this.permissionMode = '',
    this.confirmationMode = '',
    this.source = '',
    this.metadata = const <String, Object?>{},
  });

  final bool allowNetwork;
  final bool allowImportCollection;
  final String permissionMode;
  final String confirmationMode;
  final String source;
  final JsonMap metadata;

  HostInformationPermissionContext copyWith({
    bool? allowNetwork,
    bool? allowImportCollection,
    String? permissionMode,
    String? confirmationMode,
    String? source,
    JsonMap? metadata,
  }) {
    // 中文注释: 宿主权限上下文会被 runtime、CLI、GUI 等不同宿主薄桥复用，这里提供统一 copy 入口。
    return HostInformationPermissionContext(
      allowNetwork: allowNetwork ?? this.allowNetwork,
      allowImportCollection:
          allowImportCollection ?? this.allowImportCollection,
      permissionMode: permissionMode ?? this.permissionMode,
      confirmationMode: confirmationMode ?? this.confirmationMode,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  factory HostInformationPermissionContext.fromJson(JsonMap json) {
    return HostInformationPermissionContext(
      allowNetwork: ValueReaders.boolValue(json['allow_network']),
      allowImportCollection: ValueReaders.boolValue(
        json['allow_import_collection'],
      ),
      permissionMode: ValueReaders.stringValue(json['permission_mode']).trim(),
      confirmationMode: ValueReaders.stringValue(
        json['confirmation_mode'],
      ).trim(),
      source: ValueReaders.stringValue(json['source']).trim(),
      metadata: _hostInformationPermissionContextCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _hostInformationPermissionContextKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    return _hostInformationPermissionContextCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'allow_network': allowNetwork,
          'allow_import_collection': allowImportCollection,
          'permission_mode': permissionMode,
          'confirmation_mode': confirmationMode,
          'source': source,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _hostInformationPermissionContextValidatorService.requireNonBlankString(
        permissionMode,
        InformationValidationCodes.missingHostInformationPermissionMode,
      ),
    );
    result.addAll(
      _hostInformationPermissionContextValidatorService.requireNonBlankString(
        confirmationMode,
        InformationValidationCodes.missingHostInformationConfirmationMode,
      ),
    );
    result.addAll(
      _hostInformationPermissionContextValidatorService.requireNonBlankString(
        source,
        InformationValidationCodes.missingHostInformationPermissionSource,
      ),
    );
    return result;
  }
}
