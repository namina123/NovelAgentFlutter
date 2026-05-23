import 'dart:convert';

import 'json_types.dart';

class ValueReaders {
  static String stringValue(Object? value, [String fallback = '']) {
    // 中文注释: 统一把动态值转成字符串，避免迁移旧字典逻辑时到处散落 null 和 trim 判断。
    if (value == null) {
      return fallback;
    }
    return value.toString();
  }

  static bool boolValue(Object? value, [bool fallback = false]) {
    // 中文注释: 这里兼容旧项目里布尔值可能来自字符串或数字的情况，保证归一化逻辑稳定。
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) {
        return fallback;
      }
      return <String>{
        '1',
        'true',
        'yes',
        'y',
        'on',
        '是',
        '真',
        '开启',
        '启用',
      }.contains(normalized);
    }
    return fallback;
  }

  static int intValue(Object? value, [int fallback = 0]) {
    // 中文注释: 统一做整数读取，避免旧逻辑迁移后在每个服务里重复写解析分支。
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static double doubleValue(Object? value, [double fallback = 0]) {
    // 中文注释: 浮点值会用于 temperature 和 top_p 等参数，这里集中处理字符串与数字输入。
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value.trim()) ?? fallback;
    }
    return fallback;
  }

  static JsonMap mapValue(Object? value) {
    // 中文注释: 这里把动态对象安全收敛成 JSON 字典，供核心逻辑在无宿主依赖下复用。
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    if (value is Map) {
      return value.map((key, entry) => MapEntry(stringValue(key), entry));
    }
    return <String, Object?>{};
  }

  static List<Object?> objectList(Object? value) {
    // 中文注释: 旧项目大量接受“单值或数组”输入，这里集中兼容，减少迁移文件的样板代码。
    if (value is List<Object?>) {
      return List<Object?>.from(value);
    }
    if (value is List) {
      return List<Object?>.from(value);
    }
    if (value == null) {
      return <Object?>[];
    }
    return <Object?>[value];
  }

  static List<JsonMap> mapList(Object? value) {
    // 中文注释: 这里专门为目录、规则、参数定义等字典数组提供安全读取。
    return objectList(value)
        .whereType<Object?>()
        .map(mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> stringList(Object? value) {
    // 中文注释: 字符串列表在工具开关、别名、能力黑白名单里很常见，这里统一去重和去空。
    final result = <String>[];
    for (final raw in objectList(value)) {
      final text = stringValue(raw).trim();
      if (text.isNotEmpty && !result.contains(text)) {
        result.add(text);
      }
    }
    return result;
  }

  static JsonMap deepCopyMap(JsonMap value) {
    // 中文注释: 深拷贝用于把核心返回值与内部缓存隔离，防止 UI 或测试代码意外改写共享状态。
    return mapValue(jsonDecode(jsonEncode(value)));
  }

  static List<Object?> deepCopyList(List<Object?> value) {
    // 中文注释: 列表深拷贝和字典深拷贝配套，保证返回的嵌套数据可以安全传给上层消费。
    return List<Object?>.from(jsonDecode(jsonEncode(value)) as List);
  }
}
