import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_record_constants.dart';

class SessionCompressionStrategyService {
  int thresholdChars({
    JsonMap strategySettings = const <String, Object?>{},
    JsonMap modelProfile = const <String, Object?>{},
    int fallbackThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: 会话压缩阈值由独立策略服务解析，避免把百分比换算规则耦进会话状态服务。
    final explicitThreshold = ValueReaders.intValue(
      strategySettings['compression_threshold_chars'],
    );
    if (explicitThreshold > 0) {
      return _clamp(explicitThreshold);
    }
    final percent = ValueReaders.intValue(
      strategySettings['compression_threshold_percent'],
      60,
    ).clamp(5, 95);
    final contextWindow = ValueReaders.intValue(
      modelProfile['compression_context_length'],
      ValueReaders.intValue(modelProfile['context_length']),
    );
    if (contextWindow > 0) {
      final roughChars = contextWindow * 2;
      final threshold = (roughChars * percent) ~/ 100;
      return _clamp(threshold);
    }
    return _clamp(fallbackThresholdChars);
  }

  int _clamp(int value) {
    // 中文注释: 压缩阈值始终限制在核心允许范围内，避免策略配置把会话系统推到异常状态。
    if (value < SessionRecordConstants.minThresholdChars) {
      return SessionRecordConstants.minThresholdChars;
    }
    if (value > SessionRecordConstants.maxThresholdChars) {
      return SessionRecordConstants.maxThresholdChars;
    }
    return value;
  }
}
