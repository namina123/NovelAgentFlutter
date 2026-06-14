import '../common/value_readers.dart';

enum SessionTokenCountSource {
  providerExactCount,
  conservativeEstimate,
  fallbackEstimate;

  String toJsonValue() {
    // 中文注释: token 计数来源需要稳定字符串形态，方便后续快照和调试输出复用同一合同。
    return switch (this) {
      SessionTokenCountSource.providerExactCount => 'provider_exact_count',
      SessionTokenCountSource.conservativeEstimate => 'conservative_estimate',
      SessionTokenCountSource.fallbackEstimate => 'fallback_estimate',
    };
  }

  static SessionTokenCountSource fromJsonValue(Object? raw) {
    // 中文注释: 这里只接受少量明确来源名，未知值统一退回保守估算，避免 contract 读入时漂移。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'provider_exact_count' => SessionTokenCountSource.providerExactCount,
      'fallback_estimate' => SessionTokenCountSource.fallbackEstimate,
      'conservative_estimate' => SessionTokenCountSource.conservativeEstimate,
      _ => SessionTokenCountSource.conservativeEstimate,
    };
  }
}

enum SessionContextPressureLevel {
  safe,
  warning,
  critical,
  overLimit;

  String toJsonValue() {
    // 中文注释: 压力等级需要和 JSON/Map 里的公开文案脱钩，只保留稳定语义标识。
    return switch (this) {
      SessionContextPressureLevel.safe => 'safe',
      SessionContextPressureLevel.warning => 'warning',
      SessionContextPressureLevel.critical => 'critical',
      SessionContextPressureLevel.overLimit => 'over_limit',
    };
  }

  static SessionContextPressureLevel fromJsonValue(Object? raw) {
    // 中文注释: 未识别的压力等级默认按 safe 处理，避免旧数据或临时字段污染主链判断。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'warning' => SessionContextPressureLevel.warning,
      'critical' => SessionContextPressureLevel.critical,
      'over_limit' => SessionContextPressureLevel.overLimit,
      _ => SessionContextPressureLevel.safe,
    };
  }
}
