import 'dart:convert';

import '../common/json_types.dart';

class BundleChecksumService {
  const BundleChecksumService();

  String checksumOf(JsonMap bundleWithoutChecksum) {
    // 中文注释: 这里用稳定键序列化 + 轻量 FNV-1a 校验，先满足 core 合同里的“可校验”，不依赖具体 zip 实现。
    final canonical = _canonicalize(bundleWithoutChecksum);
    return _fnv1a64Hex(utf8.encode(canonical));
  }

  String _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final normalized = <String, Object?>{};
      for (final key in keys) {
        normalized[key] = _normalizedValue(value[key]);
      }
      return jsonEncode(normalized);
    }
    return jsonEncode(_normalizedValue(value));
  }

  Object? _normalizedValue(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      final normalized = <String, Object?>{};
      for (final key in keys) {
        normalized[key] = _normalizedValue(value[key]);
      }
      return normalized;
    }
    if (value is List) {
      return value.map(_normalizedValue).toList(growable: false);
    }
    return value;
  }

  String _fnv1a64Hex(List<int> bytes) {
    var hash = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = BigInt.parse('ffffffffffffffff', radix: 16);
    for (final byte in bytes) {
      hash = (hash ^ BigInt.from(byte)) & mask;
      hash = (hash * prime) & mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
