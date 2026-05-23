import 'dart:convert';

import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../ports/provider_catalog_port.dart';
import 'provider_model_catalog_seed.dart';

class ProviderCatalogService implements ProviderCatalogPort {
  ProviderCatalogService.fromJsonString(String source)
    : _catalog = ValueReaders.mapValue(jsonDecode(source));

  ProviderCatalogService.fromDocument(JsonMap document)
    : _catalog = ValueReaders.deepCopyMap(document);

  factory ProviderCatalogService.seeded() {
    // 中文注释: 默认实例直接挂接迁移过来的目录种子数据，方便 GUI 与 CLI 共用同一份内建目录。
    return ProviderCatalogService.fromJsonString(providerModelCatalogSeed);
  }

  final JsonMap _catalog;

  @override
  List<JsonMap> providerOptions({String query = '', String baseUrl = ''}) {
    // 中文注释: 这里保留旧项目的厂商匹配与排序逻辑，但把数据源改成纯 Dart 内存目录。
    final result = <JsonMap>[_manualProviderOption()];
    final scored = <JsonMap>[];
    for (final provider in providers()) {
      var score = _providerScore(provider, query, baseUrl);
      if (query.trim().isEmpty && baseUrl.trim().isEmpty) {
        score = 1;
      }
      if (score <= 0) {
        continue;
      }
      final item = ValueReaders.deepCopyMap(provider);
      item['score'] = score;
      scored.add(item);
    }
    scored.sort((a, b) {
      // 中文注释: 目录建议需要稳定按分数降序返回，方便设置页和 CLI 都使用同一排序。
      return ValueReaders.intValue(
        b['score'],
      ).compareTo(ValueReaders.intValue(a['score']));
    });
    result.addAll(scored.map(_providerOptionFromCatalog));
    return result;
  }

  @override
  List<JsonMap> providers() {
    // 中文注释: 这里返回深拷贝，避免上层直接改写核心目录缓存。
    return ValueReaders.mapList(
      _catalog['providers'],
    ).map(ValueReaders.deepCopyMap).toList(growable: false);
  }

  @override
  JsonMap providerById(String providerId) {
    // 中文注释: 厂商 ID 查询是运行配置归一化的基础入口，因此这里保持大小写敏感的精确匹配。
    final clean = providerId.trim();
    if (clean.isEmpty) {
      return <String, Object?>{};
    }
    for (final provider in providers()) {
      if (ValueReaders.stringValue(provider['id']).trim() == clean) {
        return provider;
      }
    }
    return <String, Object?>{};
  }

  @override
  JsonMap bestProviderMatch({String query = '', String baseUrl = ''}) {
    // 中文注释: 最佳匹配供自动识别厂商使用，这里保留旧项目“最高分即命中”的简单策略。
    var best = <String, Object?>{};
    var bestScore = 0;
    for (final provider in providers()) {
      final score = _providerScore(provider, query, baseUrl);
      if (score > bestScore) {
        best = provider;
        bestScore = score;
      }
    }
    return best;
  }

  @override
  List<JsonMap> modelSuggestions({
    String query = '',
    String providerId = '',
    bool includeImage = true,
    int limit = 16,
  }) {
    // 中文注释: 模型候选列表是设置页与 CLI 的共享逻辑，因此这里不混入任何 UI 专属状态。
    final scored = <JsonMap>[];
    final cleanProvider = providerId.trim();
    for (final provider in providers()) {
      final currentProviderId = ValueReaders.stringValue(provider['id']);
      final providerBias =
          cleanProvider.isNotEmpty && currentProviderId == cleanProvider
          ? 60
          : 0;
      for (final model in ValueReaders.mapList(provider['models'])) {
        final modelType = ValueReaders.stringValue(model['type'], 'text');
        if (!includeImage && modelType == 'image') {
          continue;
        }
        if (modelType == 'text' &&
            !ValueReaders.boolValue(model['supports_tools'])) {
          continue;
        }
        var score = providerBias + _modelScore(model, query);
        if (query.trim().isEmpty && providerBias > 0) {
          score += 1;
        }
        if (query.trim().isEmpty &&
            ValueReaders.boolValue(model['recommended'])) {
          score += 30;
        }
        if (score <= 0) {
          continue;
        }
        final item = ValueReaders.deepCopyMap(model);
        item['provider_id'] = currentProviderId;
        item['provider_label'] = ValueReaders.stringValue(
          provider['label'],
          currentProviderId,
        );
        item['kind'] = ValueReaders.stringValue(
          provider['kind'],
          'openai_compatible',
        );
        item['score'] = score;
        scored.add(item);
      }
    }
    scored.sort((a, b) {
      // 中文注释: 模型建议排序和 Godot 旧项目一致，始终按得分倒序输出。
      return ValueReaders.intValue(
        b['score'],
      ).compareTo(ValueReaders.intValue(a['score']));
    });
    return scored.take(limit).map(ValueReaders.deepCopyMap).toList();
  }

  @override
  JsonMap matchModel(String modelId, {String providerId = ''}) {
    // 中文注释: 这里保留“先精确命中，再接受高置信建议”的旧策略，方便兼容手输模型名。
    final query = modelId.trim();
    if (query.isEmpty) {
      return <String, Object?>{};
    }
    final candidates = modelSuggestions(
      query: query,
      providerId: providerId,
      includeImage: true,
      limit: 8,
    );
    for (final item in candidates) {
      final currentId = ValueReaders.stringValue(item['id']).toLowerCase();
      if (currentId == query.toLowerCase()) {
        return item;
      }
    }
    if (candidates.isEmpty) {
      return <String, Object?>{};
    }
    return ValueReaders.intValue(candidates.first['score']) >= 80
        ? candidates.first
        : <String, Object?>{};
  }

  @override
  JsonMap modelProfileDefaults(JsonMap modelEntry, {String credentialId = ''}) {
    // 中文注释: 这里把目录模型条目转换成运行模型默认值，供配置创建与自动补全复用。
    if (modelEntry.isEmpty) {
      return <String, Object?>{};
    }
    final modelId = ValueReaders.stringValue(modelEntry['id']).trim();
    final modelType = ValueReaders.stringValue(modelEntry['type'], 'text');
    return <String, Object?>{
      'name': ValueReaders.stringValue(modelEntry['label'], modelId),
      'purpose': modelType == 'text' ? '通用创作' : '图片生成',
      'credential_id': credentialId,
      'kind': ValueReaders.stringValue(modelEntry['kind'], 'openai_compatible'),
      'model': modelId,
      'context_length': ValueReaders.intValue(
        modelEntry['context_length'],
        100000,
      ),
      'compression_context_length': ValueReaders.intValue(
        modelEntry['compression_context_length'],
        80000,
      ),
      'max_output_tokens': ValueReaders.intValue(
        modelEntry['max_output_tokens'],
        65536,
      ),
      'thinking_parameter_format': ValueReaders.stringValue(
        modelEntry['thinking_parameter_format'],
        'none',
      ),
      'streaming_enabled': ValueReaders.boolValue(
        modelEntry['streaming_enabled'],
        true,
      ),
      'supports_tools': ValueReaders.boolValue(
        modelEntry['supports_tools'],
        modelType == 'text',
      ),
      'supports_image_generation': ValueReaders.boolValue(
        modelEntry['supports_image_generation'],
        modelType == 'image',
      ),
    };
  }

  @override
  JsonMap catalogParameterSummary(JsonMap modelEntry) {
    // 中文注释: 参数摘要只保留支持/禁用名单，供运行配置能力判断复用。
    return <String, Object?>{
      'supported_parameters': ValueReaders.stringList(
        modelEntry['supported_parameters'],
      ),
      'unsupported_parameters': ValueReaders.stringList(
        modelEntry['unsupported_parameters'],
      ),
    };
  }

  JsonMap _manualProviderOption() {
    // 中文注释: 手动接口选项是旧设置页的重要兜底能力，这里继续作为目录返回值的首项。
    return <String, Object?>{
      'id': '',
      'label': '无厂商 / 手动接口',
      'kind': 'openai_compatible',
      'default_base_url': '',
      'score': 9999,
    };
  }

  JsonMap _providerOptionFromCatalog(JsonMap provider) {
    // 中文注释: 目录原始条目包含模型等细节，设置候选只需要投影出选择器关心的字段。
    return <String, Object?>{
      'id': ValueReaders.stringValue(provider['id']),
      'label': ValueReaders.stringValue(
        provider['label'],
        ValueReaders.stringValue(provider['id']),
      ),
      'kind': ValueReaders.stringValue(provider['kind'], 'openai_compatible'),
      'default_base_url': ValueReaders.stringValue(
        provider['default_base_url'],
      ),
      'score': ValueReaders.intValue(provider['score']),
    };
  }

  int _providerScore(JsonMap provider, String query, String baseUrl) {
    // 中文注释: 厂商匹配同时参考名称和 base URL 提示，尽量还原旧项目的自动识别体验。
    var score = 0;
    final queryText = query.trim().toLowerCase();
    final urlText = baseUrl.trim().toLowerCase();
    if (queryText.isNotEmpty) {
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(provider['label']), queryText),
      );
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(provider['id']), queryText),
      );
      for (final alias in ValueReaders.objectList(provider['aliases'])) {
        score = _max(
          score,
          _textScore(ValueReaders.stringValue(alias), queryText),
        );
      }
    }
    if (urlText.isNotEmpty) {
      for (final hint in ValueReaders.objectList(provider['base_url_hints'])) {
        final cleanHint = ValueReaders.stringValue(hint).trim().toLowerCase();
        if (cleanHint.isNotEmpty && urlText.contains(cleanHint)) {
          score = _max(score, 120);
        }
      }
    }
    if (queryText.isEmpty && urlText.isEmpty) {
      return 1;
    }
    return score;
  }

  int _modelScore(JsonMap model, String query) {
    // 中文注释: 模型建议排序尽量偏向推荐模型，但不覆盖精确或前缀命中。
    final queryText = query.trim().toLowerCase();
    if (queryText.isEmpty) {
      return ValueReaders.boolValue(model['recommended']) ? 1 : 0;
    }
    var score = _max(
      _textScore(ValueReaders.stringValue(model['label']), queryText),
      _textScore(ValueReaders.stringValue(model['id']), queryText),
    );
    for (final alias in ValueReaders.objectList(model['aliases'])) {
      score = _max(
        score,
        _textScore(ValueReaders.stringValue(alias), queryText),
      );
    }
    if (ValueReaders.boolValue(model['recommended']) && score > 0) {
      score += 8;
    }
    return score;
  }

  int _textScore(String value, String query) {
    // 中文注释: 文本评分规则完全是纯算法，放在 core 里后 GUI 和 CLI 的搜索体验才一致。
    final haystack = value.trim().toLowerCase();
    if (haystack.isEmpty || query.isEmpty) {
      return 0;
    }
    if (haystack == query) {
      return 140;
    }
    if (haystack.startsWith(query)) {
      return 110;
    }
    if (haystack.contains(query)) {
      return 80;
    }
    final compactHaystack = haystack.replaceAll(RegExp(r'[-_/ ]'), '');
    final compactQuery = query.replaceAll(RegExp(r'[-_/ ]'), '');
    if (compactQuery.isNotEmpty && compactHaystack.contains(compactQuery)) {
      return 70;
    }
    return 0;
  }

  int _max(int left, int right) {
    // 中文注释: 小工具函数单独存在，是为了让评分逻辑保持直白可读。
    return left > right ? left : right;
  }
}
