import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'domain_tool_validation_codes.dart';

const _domainToolErrorValidatorService = OpenJsonStructureValidatorService();

class DomainToolError {
  const DomainToolError({
    required this.errorCode,
    this.message = '',
    this.errorDetails = const <String, Object?>{},
    this.retryable = false,
    this.metadata = const <String, Object?>{},
  });

  final String errorCode;
  final String message;
  final JsonMap errorDetails;
  final bool retryable;
  final JsonMap metadata;

  DomainToolError copyWith({
    String? errorCode,
    String? message,
    JsonMap? errorDetails,
    bool? retryable,
    JsonMap? metadata,
  }) {
    // 中文注释: 错误合同只承载结构化失败信息，不把宿主异常对象直接泄漏到 core 合同。
    return DomainToolError(
      errorCode: errorCode ?? this.errorCode,
      message: message ?? this.message,
      errorDetails: errorDetails ?? this.errorDetails,
      retryable: retryable ?? this.retryable,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DomainToolError.fromJson(JsonMap json) {
    return DomainToolError(
      errorCode: ValueReaders.stringValue(json['error_code']).trim(),
      message: ValueReaders.stringValue(json['message']).trim(),
      errorDetails: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['error_details']),
      ),
      retryable: ValueReaders.boolValue(json['retryable']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'error_code': errorCode,
      'message': message,
      'error_details': ValueReaders.deepCopyMap(errorDetails),
      'retryable': retryable,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _domainToolErrorValidatorService.requireNonBlankString(
        errorCode,
        DomainToolValidationCodes.missingErrorCode,
      ),
    );
    return result;
  }
}
