import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'provider_profile_constants.dart';

class ProviderCustomParameterService {
  String normalizeCustomParameterType(String valueType) {
    // 中文注释: 自定义参数类型需要稳定落在支持集合里，否则后续请求构造会出现分支漂移。
    final normalized = valueType.trim().toLowerCase();
    if (ProviderProfileConstants.customParameterTypes.contains(normalized)) {
      return normalized;
    }
    return 'string';
  }

  List<Object?> normalizeCustomParameters(Object? parameters) {
    // 中文注释: 对外保留旧接口语义，但实际统一走冲突消解和类型归一化逻辑。
    return resolveCustomParameters(parameters);
  }

  bool supportsStandardParameter(JsonMap profile, String key) {
    // 中文注释: 标准参数支持性读取 capability 白名单与黑名单，不让宿主各自猜测兼容性。
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      return false;
    }
    final capability = ValueReaders.mapValue(
      profile['provider_model_capability'],
    );
    final unsupported = _normalizedKeyList(
      capability['unsupported_parameters'],
    );
    if (unsupported.contains(normalizedKey)) {
      return false;
    }
    final supported = _normalizedKeyList(capability['supported_parameters']);
    if (supported.isNotEmpty) {
      return supported.contains(normalizedKey);
    }
    return true;
  }

  bool supportsCustomParameter(JsonMap profile, String key) {
    // 中文注释: 自定义参数这里只受 capability 黑名单约束，便于高级参数继续透传。
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      return false;
    }
    final capability = ValueReaders.mapValue(
      profile['provider_model_capability'],
    );
    return !_normalizedKeyList(
      capability['unsupported_parameters'],
    ).contains(normalizedKey);
  }

  List<Object?> resolveCustomParameters(
    Object? parameters, {
    List<String> excludedKeys = const <String>[],
  }) {
    // 中文注释: 参数冲突、互斥组和类型转换统一在这里处理，避免请求构造层沾上业务规则。
    final result = <Object?>[];
    final excluded = _normalizedKeyList(excludedKeys);
    for (final raw in ValueReaders.mapList(parameters)) {
      if (raw.containsKey('enabled') &&
          !ValueReaders.boolValue(raw['enabled'], true)) {
        continue;
      }
      final key = ValueReaders.stringValue(raw['key'] ?? raw['field']).trim();
      if (key.isEmpty || excluded.contains(key)) {
        continue;
      }
      final valueType = normalizeCustomParameterType(
        ValueReaders.stringValue(raw['type'], 'string'),
      );
      final conflicts = _normalizedKeyList(raw['conflicts_with']);
      for (final existing in List<JsonMap>.from(
        result.map((item) => ValueReaders.mapValue(item)),
      )) {
        final existingKey = ValueReaders.stringValue(existing['key']);
        if (conflicts.contains(existingKey)) {
          _removeParameterByKey(result, existingKey);
          continue;
        }
        final existingConflicts = _normalizedKeyList(
          existing['conflicts_with'],
        );
        if (existingConflicts.contains(key)) {
          _removeParameterByKey(result, existingKey);
        }
      }
      final exclusiveGroup = ValueReaders.stringValue(
        raw['exclusive_group'],
      ).trim();
      if (exclusiveGroup.isNotEmpty) {
        _removeParameterByGroup(result, exclusiveGroup);
      }
      _removeParameterByKey(result, key);
      final normalized = <String, Object?>{
        'key': key,
        'type': valueType,
        'value': coerceCustomParameterValue(
          raw['value'] ?? raw['default'],
          valueType,
        ),
      };
      for (final optionalKey in <String>[
        'description',
        'exclusive_group',
        'source_type',
        'source_id',
      ]) {
        if (raw.containsKey(optionalKey)) {
          normalized[optionalKey] = raw[optionalKey];
        }
      }
      if (conflicts.isNotEmpty) {
        normalized['conflicts_with'] = conflicts;
      }
      result.add(normalized);
    }
    return result;
  }

  Object? coerceCustomParameterValue(Object? value, String valueType) {
    // 中文注释: 自定义参数值类型转换在核心统一执行，避免不同适配器出现不一致的编码结果。
    switch (normalizeCustomParameterType(valueType)) {
      case 'boolean':
        return ValueReaders.boolValue(value);
      case 'integer':
        return ValueReaders.intValue(value);
      case 'number':
        return ValueReaders.doubleValue(value);
      case 'json':
        if (value is Map ||
            value is List ||
            value is num ||
            value is bool ||
            value == null) {
          return value;
        }
        return ValueReaders.stringValue(value);
      default:
        return ValueReaders.stringValue(value);
    }
  }

  List<String> _normalizedKeyList(Object? values) {
    // 中文注释: 参数 key 去空去重逻辑集中在这里，减少主流程里的重复样板代码。
    final result = <String>[];
    for (final raw in ValueReaders.stringList(values)) {
      final key = raw.trim();
      if (key.isNotEmpty && !result.contains(key)) {
        result.add(key);
      }
    }
    return result;
  }

  void _removeParameterByKey(List<Object?> parameters, String key) {
    // 中文注释: key 冲突删除是参数消解内部细节，不应暴露给运行配置层承担。
    parameters.removeWhere((item) {
      return ValueReaders.stringValue(ValueReaders.mapValue(item)['key']) ==
          key;
    });
  }

  void _removeParameterByGroup(List<Object?> parameters, String group) {
    // 中文注释: 互斥组删除和同名覆盖是两类规则，因此单独抽一个函数避免语义混乱。
    parameters.removeWhere((item) {
      return ValueReaders.stringValue(
            ValueReaders.mapValue(item)['exclusive_group'],
          ).trim() ==
          group;
    });
  }
}
