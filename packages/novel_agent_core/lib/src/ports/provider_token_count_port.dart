import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../llm/chat_request.dart';
import '../session/session_context_pressure_enums.dart';

class ProviderTokenCountRequest {
  const ProviderTokenCountRequest({
    required this.providerId,
    required this.modelId,
    required this.request,
    this.metadata = const <String, Object?>{},
  });

  final String providerId;
  final String modelId;
  final ChatRequest request;
  final JsonMap metadata;
}

class ProviderTokenCountResult {
  const ProviderTokenCountResult({
    required this.providerId,
    required this.modelId,
    required this.exactInputTokens,
    this.countSource = SessionTokenCountSource.providerExactCount,
    this.reportedUsage = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String providerId;
  final String modelId;
  final int exactInputTokens;
  final SessionTokenCountSource countSource;
  final JsonMap reportedUsage;
  final JsonMap metadata;

  bool get hasExactInputTokens => exactInputTokens >= 0;

  JsonMap toJson() {
    // 中文注释: exact count 结果只输出稳定的输入 token 与辅助 usage，避免和保守估算混成一个对象。
    return <String, Object?>{
      'provider_id': providerId,
      'model_id': modelId,
      'exact_input_tokens': exactInputTokens,
      'count_source': countSource.toJsonValue(),
      'reported_usage': ValueReaders.deepCopyMap(reportedUsage),
      'metadata': ValueReaders.deepCopyMap(metadata),
      'has_exact_input_tokens': hasExactInputTokens,
    };
  }

  factory ProviderTokenCountResult.fromJson(JsonMap json) {
    // 中文注释: 这里只恢复 exact count 合同和辅助 usage，未知字段不参与主链判断。
    return ProviderTokenCountResult(
      providerId: ValueReaders.stringValue(json['provider_id']),
      modelId: ValueReaders.stringValue(json['model_id']),
      exactInputTokens: ValueReaders.intValue(json['exact_input_tokens']),
      countSource: SessionTokenCountSource.fromJsonValue(json['count_source']),
      reportedUsage: ValueReaders.mapValue(json['reported_usage']),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: exact count 结果至少要有提供方、模型和非负 token，才能被后续 snapshot 当成有效 hint。
    final issues = <String>[];
    if (providerId.trim().isEmpty) {
      issues.add('missing_provider_id');
    }
    if (modelId.trim().isEmpty) {
      issues.add('missing_model_id');
    }
    if (exactInputTokens < 0) {
      issues.add('negative_exact_input_tokens');
    }
    if (countSource != SessionTokenCountSource.providerExactCount) {
      issues.add('invalid_provider_token_count_source');
    }
    return issues;
  }
}

abstract class ProviderTokenCountPort {
  Future<ProviderTokenCountResult?> countTokens(
    ProviderTokenCountRequest request,
  );
}
