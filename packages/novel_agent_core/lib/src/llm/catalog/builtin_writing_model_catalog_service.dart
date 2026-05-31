import 'dart:convert';

import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'builtin_writing_model_catalog_seed.dart';
import 'builtin_writing_model_descriptor.dart';
import 'writing_model_provider_offering_override.dart';
import 'writing_model_reasoning_descriptor.dart';

class BuiltinWritingModelCatalogService {
  BuiltinWritingModelCatalogService.fromJsonString(String source)
    : _catalog = ValueReaders.mapValue(jsonDecode(source));

  BuiltinWritingModelCatalogService.fromDocument(JsonMap document)
    : _catalog = ValueReaders.deepCopyMap(document);

  factory BuiltinWritingModelCatalogService.seeded() {
    // 中文注释: 写作模型事实目录先独立于旧 provider catalog 存在，降低改造首轮风险。
    return BuiltinWritingModelCatalogService.fromJsonString(
      builtinWritingModelCatalogSeed,
    );
  }

  final JsonMap _catalog;

  int get version => ValueReaders.intValue(_catalog['version'], 1);

  List<BuiltinWritingModelDescriptor> models() {
    // 中文注释: 这里统一把 JSON 目录投影成强类型对象，后续 settings、workbench、CLI 才能共用同一事实层。
    return ValueReaders.mapList(
      _catalog['models'],
    ).map(_descriptorFromMap).toList(growable: false);
  }

  BuiltinWritingModelDescriptor? modelByCanonicalId(String canonicalModelId) {
    // 中文注释: canonical id 查询供后续 offering override、热更新 patch 和稳定测试直接复用。
    final clean = canonicalModelId.trim();
    if (clean.isEmpty) {
      return null;
    }
    for (final model in models()) {
      if (model.canonicalModelId == clean) {
        return model;
      }
    }
    return null;
  }

  BuiltinWritingModelDescriptor? matchByProviderModelId({
    required String providerId,
    required String modelId,
  }) {
    // 中文注释: 这里优先按 offering id 命中，方便后续把聚合平台和原厂模型稳定关联到 canonical 条目。
    final cleanProviderId = providerId.trim();
    final cleanModelId = modelId.trim().toLowerCase();
    if (cleanProviderId.isEmpty || cleanModelId.isEmpty) {
      return null;
    }
    for (final model in models()) {
      for (final offering in model.providerOfferings) {
        if (offering.providerId == cleanProviderId &&
            offering.providerModelId.trim().toLowerCase() == cleanModelId) {
          return model;
        }
      }
    }
    return null;
  }

  BuiltinWritingModelDescriptor? matchByAlias(String query) {
    // 中文注释: 别名匹配供手输模型与导入场景复用，但这层只做保守精确匹配，不做过度模糊猜测。
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return null;
    }
    for (final model in models()) {
      if (model.displayName.trim().toLowerCase() == clean ||
          model.canonicalModelId.trim().toLowerCase() == clean) {
        return model;
      }
      for (final alias in model.aliases) {
        if (alias.trim().toLowerCase() == clean) {
          return model;
        }
      }
    }
    return null;
  }

  BuiltinWritingModelDescriptor _descriptorFromMap(JsonMap raw) {
    // 中文注释: 强类型映射集中在这一层，避免后续多个消费者各自猜目录字段。
    return BuiltinWritingModelDescriptor(
      canonicalModelId: ValueReaders.stringValue(raw['canonical_model_id']),
      vendorId: ValueReaders.stringValue(raw['vendor_id']),
      vendorLabel: ValueReaders.stringValue(raw['vendor_label']),
      family: ValueReaders.stringValue(raw['family']),
      snapshot: ValueReaders.stringValue(raw['snapshot']),
      displayName: ValueReaders.stringValue(raw['display_name']),
      aliases: ValueReaders.stringList(raw['aliases']),
      providerOfferings: ValueReaders.mapList(
        raw['provider_offerings'],
      ).map(_offeringFromMap).toList(growable: false),
      contextLength: ValueReaders.intValue(raw['context_length'], 100000),
      compressionContextLength: ValueReaders.intValue(
        raw['compression_context_length'],
        80000,
      ),
      maxOutputTokens: ValueReaders.intValue(raw['max_output_tokens'], 65536),
      supportsTemperature: ValueReaders.boolValue(
        raw['supports_temperature'],
        true,
      ),
      supportsTopP: ValueReaders.boolValue(raw['supports_top_p'], true),
      supportsStreaming: ValueReaders.boolValue(raw['supports_streaming'], true),
      supportsTools: ValueReaders.boolValue(raw['supports_tools'], true),
      supportsToolChoice: ValueReaders.boolValue(
        raw['supports_tool_choice'],
      ),
      supportsFileAttachments: ValueReaders.boolValue(
        raw['supports_file_attachments'],
      ),
      supportsImageAttachments: ValueReaders.boolValue(
        raw['supports_image_attachments'],
      ),
      supportsAttachmentUrlsOnly: ValueReaders.boolValue(
        raw['supports_attachment_urls_only'],
      ),
      supportsMultiAttachments: ValueReaders.boolValue(
        raw['supports_multi_attachments'],
      ),
      supportedParameters: ValueReaders.stringList(raw['supported_parameters']),
      unsupportedParameters: ValueReaders.stringList(
        raw['unsupported_parameters'],
      ),
      reasoning: _reasoningFromMap(ValueReaders.mapValue(raw['reasoning'])),
      status: ValueReaders.stringValue(raw['status'], 'active'),
      notes: ValueReaders.stringValue(raw['notes']),
    );
  }

  WritingModelProviderOfferingOverride _offeringFromMap(JsonMap raw) {
    // 中文注释: offering override 和 canonical facts 分开建模，才能容纳聚合平台改写 thinking 参数的现实情况。
    return WritingModelProviderOfferingOverride(
      providerId: ValueReaders.stringValue(raw['provider_id']),
      providerLabel: ValueReaders.stringValue(raw['provider_label']),
      providerModelId: ValueReaders.stringValue(raw['provider_model_id']),
      baseUrlHint: ValueReaders.stringValue(raw['base_url_hint']),
      reasoningOverride: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['reasoning_override']),
      ),
      supportedParametersOverride: ValueReaders.stringList(
        raw['supported_parameters_override'],
      ),
      notes: ValueReaders.stringValue(raw['notes']),
    );
  }

  WritingModelReasoningDescriptor _reasoningFromMap(JsonMap raw) {
    // 中文注释: reasoning 描述先只覆盖写作场景真正要用的能力面，后续再逐步扩展。
    return WritingModelReasoningDescriptor(
      supported: ValueReaders.boolValue(raw['supported']),
      modeBehavior: ValueReaders.stringValue(
        raw['mode_behavior'],
        'unsupported',
      ),
      canToggle: ValueReaders.boolValue(raw['can_toggle']),
      defaultEnabled: ValueReaders.boolValue(raw['default_enabled']),
      supportsEffort: ValueReaders.boolValue(raw['supports_effort']),
      effortOptions: ValueReaders.stringList(raw['effort_options']),
      defaultEffort: ValueReaders.stringValue(raw['default_effort']),
      toggleParameterStrategy: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['toggle_parameter_strategy']),
      ),
      effortParameterStrategy: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(raw['effort_parameter_strategy']),
      ),
    );
  }
}
