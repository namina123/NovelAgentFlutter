import 'dart:convert';

import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../ports/provider_capability_port.dart';
import 'provider_model_capabilities_seed.dart';

class ProviderCapabilityResolver implements ProviderCapabilityPort {
  ProviderCapabilityResolver.fromJsonString(String source)
    : _catalog = ValueReaders.mapValue(jsonDecode(source));

  ProviderCapabilityResolver.fromDocument(JsonMap document)
    : _catalog = ValueReaders.deepCopyMap(document);

  factory ProviderCapabilityResolver.seeded() {
    // 中文注释: 默认实例直接使用迁移后的能力规则种子，先把旧项目的匹配规则稳定收回 core。
    return ProviderCapabilityResolver.fromJsonString(
      providerModelCapabilitiesSeed,
    );
  }

  final JsonMap _catalog;

  @override
  JsonMap resolve(
    JsonMap credential,
    JsonMap modelProfile, {
    JsonMap runtimeProfile = const <String, Object?>{},
  }) {
    // 中文注释: 能力解析器只负责纯规则合并，不触碰网络、文件或宿主对象。
    final result = _blankResolution();
    for (final provider in ValueReaders.mapList(_catalog['providers'])) {
      if (!_matches(
        provider['match'],
        credential,
        modelProfile,
        runtimeProfile,
      )) {
        continue;
      }
      _mergeRule(result, provider, 'provider');
      for (final model in ValueReaders.mapList(provider['models'])) {
        if (_matches(
          model['match'],
          credential,
          modelProfile,
          runtimeProfile,
        )) {
          _mergeRule(result, model, 'model');
        }
      }
    }
    for (final globalRule in ValueReaders.mapList(_catalog['model_rules'])) {
      if (_matches(
        globalRule['match'],
        credential,
        modelProfile,
        runtimeProfile,
      )) {
        _mergeRule(result, globalRule, 'model');
      }
    }
    return result;
  }

  JsonMap _blankResolution() {
    // 中文注释: 空解析结果统一带完整骨架，避免上层每次再判断字段是否存在。
    final defaults = ValueReaders.mapValue(_catalog['defaults']);
    return <String, Object?>{
      'version': ValueReaders.intValue(_catalog['version']),
      'provider_id': '',
      'provider_label': '',
      'matched_rule_ids': <String>[],
      'capabilities': ValueReaders.mapValue(defaults['capabilities']),
      'profile_defaults': <String, Object?>{},
      'request_parameters': <Object?>[],
      'parameter_definitions': <Object?>[],
      'excluded_parameters': <String>[],
    };
  }

  void _mergeRule(JsonMap result, JsonMap rule, String sourceType) {
    // 中文注释: 规则合并严格按旧项目顺序执行，后匹配的字段覆盖先匹配的字段。
    final ruleId = ValueReaders.stringValue(rule['id']).trim();
    final matchedIds = ValueReaders.stringList(result['matched_rule_ids']);
    if (ruleId.isNotEmpty && !matchedIds.contains(ruleId)) {
      matchedIds.add(ruleId);
    }
    result['matched_rule_ids'] = matchedIds;
    if (sourceType == 'provider') {
      result['provider_id'] = ruleId;
      result['provider_label'] = ValueReaders.stringValue(
        rule['label'],
        ruleId,
      );
    }

    final capabilities = ValueReaders.mapValue(result['capabilities']);
    final ruleCapabilities = ValueReaders.mapValue(rule['capabilities']);
    ruleCapabilities.forEach((key, value) {
      // 中文注释: capability 是平面字段集合，这里直接覆盖可以保持语义明确。
      capabilities[key] = value;
    });
    result['capabilities'] = capabilities;

    final profileDefaults = ValueReaders.mapValue(result['profile_defaults']);
    final ruleDefaults = ValueReaders.mapValue(rule['profile_defaults']);
    ruleDefaults.forEach((key, value) {
      // 中文注释: profile 默认值遵循后命中覆盖前命中，兼容模型级规则覆写厂商级规则。
      profileDefaults[key] = value;
    });
    result['profile_defaults'] = profileDefaults;

    _appendUniqueParameters(
      result,
      'request_parameters',
      rule['request_parameters'] ?? rule['parameters'],
      sourceType,
      ruleId,
    );
    _appendUniqueParameters(
      result,
      'parameter_definitions',
      rule['parameter_definitions'],
      sourceType,
      ruleId,
    );
    _appendStrings(result, 'excluded_parameters', rule['excluded_parameters']);
  }

  void _appendUniqueParameters(
    JsonMap result,
    String targetKey,
    Object? parameters,
    String sourceType,
    String sourceId,
  ) {
    // 中文注释: 参数定义允许重复追加，由运行配置层再做 key 冲突和互斥消解。
    final values = ValueReaders.objectList(result[targetKey]);
    for (final raw in ValueReaders.mapList(parameters)) {
      final item = ValueReaders.deepCopyMap(raw);
      final key = ValueReaders.stringValue(item['key']).trim();
      if (key.isEmpty) {
        continue;
      }
      item['key'] = key;
      item['source_type'] = ValueReaders.stringValue(
        item['source_type'],
        sourceType,
      );
      item['source_id'] = ValueReaders.stringValue(item['source_id'], sourceId);
      values.add(item);
    }
    result[targetKey] = values;
  }

  void _appendStrings(JsonMap result, String targetKey, Object? values) {
    // 中文注释: 排除字段名单需要保持去重，否则后续支持性判断会出现重复噪声。
    final target = ValueReaders.stringList(result[targetKey]);
    for (final item in ValueReaders.stringList(values)) {
      if (!target.contains(item)) {
        target.add(item);
      }
    }
    result[targetKey] = target;
  }

  bool _matches(
    Object? matchRule,
    JsonMap credential,
    JsonMap modelProfile,
    JsonMap runtimeProfile,
  ) {
    // 中文注释: 匹配规则保留 any/all/mode 语义，用来迁移旧项目的能力目录 DSL。
    final rule = ValueReaders.mapValue(matchRule);
    if (rule.isEmpty) {
      return true;
    }
    if (rule.containsKey('any')) {
      for (final child in ValueReaders.objectList(rule['any'])) {
        if (_matches(child, credential, modelProfile, runtimeProfile)) {
          return true;
        }
      }
      return false;
    }
    if (rule.containsKey('all')) {
      for (final child in ValueReaders.objectList(rule['all'])) {
        if (!_matches(child, credential, modelProfile, runtimeProfile)) {
          return false;
        }
      }
      return true;
    }

    final mode = ValueReaders.stringValue(
      rule['mode'],
      'all',
    ).trim().toLowerCase();
    final checks = <bool?>[
      _fieldMatches(
        _runtimeValue('kind', credential, modelProfile, runtimeProfile),
        rule,
        'kind',
        'exact',
      ),
      _fieldMatches(
        _runtimeValue('base_url', credential, modelProfile, runtimeProfile),
        rule,
        'base_url_contains',
        'contains',
      ),
      _fieldMatches(
        _runtimeValue(
          'name',
          credential,
          const <String, Object?>{},
          const <String, Object?>{},
        ),
        rule,
        'credential_name_contains',
        'contains',
      ),
      _fieldMatches(
        _runtimeValue(
          'credential_name',
          credential,
          modelProfile,
          runtimeProfile,
        ),
        rule,
        'provider_name_contains',
        'contains',
      ),
      _fieldMatches(
        _runtimeValue('model', credential, modelProfile, runtimeProfile),
        rule,
        'model_exact',
        'exact',
      ),
      _fieldMatches(
        _runtimeValue('model', credential, modelProfile, runtimeProfile),
        rule,
        'model_contains',
        'contains',
      ),
      _fieldMatches(
        _runtimeValue('model', credential, modelProfile, runtimeProfile),
        rule,
        'model_prefixes',
        'prefix',
      ),
      _fieldMatches(
        _runtimeValue('model', credential, modelProfile, runtimeProfile),
        rule,
        'model_suffixes',
        'suffix',
      ),
    ];
    var relevant = 0;
    var matched = 0;
    for (final check in checks) {
      if (check == null) {
        continue;
      }
      relevant += 1;
      if (check) {
        matched += 1;
      }
    }
    if (relevant == 0) {
      return true;
    }
    return mode == 'any' ? matched > 0 : matched == relevant;
  }

  String _runtimeValue(
    String key,
    JsonMap credential,
    JsonMap modelProfile,
    JsonMap runtimeProfile,
  ) {
    // 中文注释: 运行值读取顺序必须稳定，确保运行态覆盖模型态，再覆盖 credential 态。
    if (runtimeProfile.containsKey(key)) {
      return ValueReaders.stringValue(runtimeProfile[key]);
    }
    if (modelProfile.containsKey(key)) {
      return ValueReaders.stringValue(modelProfile[key]);
    }
    if (credential.containsKey(key)) {
      return ValueReaders.stringValue(credential[key]);
    }
    if (key == 'credential_name') {
      return ValueReaders.stringValue(credential['name']);
    }
    return '';
  }

  bool? _fieldMatches(String value, JsonMap rule, String key, String mode) {
    // 中文注释: 单字段匹配支持 exact/prefix/suffix/contains，保持与旧规则文件兼容。
    if (!rule.containsKey(key)) {
      return null;
    }
    final haystack = value.trim().toLowerCase();
    for (final raw in ValueReaders.objectList(rule[key])) {
      final needle = ValueReaders.stringValue(raw).trim().toLowerCase();
      if (needle.isEmpty) {
        continue;
      }
      switch (mode) {
        case 'exact':
          if (haystack == needle) {
            return true;
          }
          break;
        case 'prefix':
          if (haystack.startsWith(needle)) {
            return true;
          }
          break;
        case 'suffix':
          if (haystack.endsWith(needle)) {
            return true;
          }
          break;
        default:
          if (haystack.contains(needle)) {
            return true;
          }
          break;
      }
    }
    return false;
  }
}
