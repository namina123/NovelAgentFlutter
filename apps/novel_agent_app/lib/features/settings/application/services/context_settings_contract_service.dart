import 'package:novel_agent_core/novel_agent_core.dart';

class ContextSettingsContractService {
  const ContextSettingsContractService();

  static const String modelContextWindowTokensKey =
      'model_context_window_tokens';
  static const String contextWindowHintTokensKey = 'context_window_hint_tokens';
  static const String warningThresholdRatioKey = 'warning_threshold_ratio';
  static const String criticalThresholdRatioKey = 'critical_threshold_ratio';
  static const String reservedOutputTokensKey = 'reserved_output_tokens';
  static const String autoCompactPolicyKey = 'auto_compact_policy';
  static const String preferExactCountKey = 'prefer_exact_count';
  static const String compactionOutputPolicyKey = 'compaction_output_policy';

  static const String compressionThresholdPercentKey =
      'compression_threshold_percent';
  static const String contextPackBudgetPercentKey =
      'context_pack_budget_percent';
  static const String maxContextFileCharsKey = 'max_context_file_chars';
  static const String maxContextFilesPerKindKey = 'max_context_files_per_kind';
  static const String reservedOutputCharsKey = 'reserved_output_chars';

  JsonMap normalizeForStorage(JsonMap raw) {
    // 中文注释: 这里把上下文设置统一收敛成 token 压力合同，同时保留旧字符字段作为兼容桥。
    final normalized = ValueReaders.deepCopyMap(raw);
    final modelWindow = _modelWindowTokens(normalized);
    final hintWindow = _hintWindowTokens(normalized, modelWindow);
    final warningRatio = _warningRatio(normalized);
    final criticalRatio = _criticalRatio(normalized, warningRatio);
    final reservedOutputTokens = _reservedOutputTokens(normalized);
    normalized[modelContextWindowTokensKey] = modelWindow;
    normalized[contextWindowHintTokensKey] = hintWindow;
    normalized[warningThresholdRatioKey] = warningRatio;
    normalized[criticalThresholdRatioKey] = criticalRatio;
    normalized[reservedOutputTokensKey] = reservedOutputTokens;
    normalized[autoCompactPolicyKey] = _stringValue(
      normalized[autoCompactPolicyKey],
      'warning_and_critical',
    );
    normalized[preferExactCountKey] = ValueReaders.boolValue(
      normalized[preferExactCountKey],
    );
    normalized[compactionOutputPolicyKey] = _stringValue(
      normalized[compactionOutputPolicyKey],
      'structured_bullets',
    );
    normalized[compressionThresholdPercentKey] =
        normalized.containsKey(compressionThresholdPercentKey)
        ? _intValue(normalized[compressionThresholdPercentKey], 60)
        : _percentFromRatio(warningRatio);
    normalized[contextPackBudgetPercentKey] = _intValue(
      normalized[contextPackBudgetPercentKey],
      55,
    );
    normalized[maxContextFileCharsKey] = _intValue(
      normalized[maxContextFileCharsKey],
      2400,
    );
    normalized[maxContextFilesPerKindKey] = _intValue(
      normalized[maxContextFilesPerKindKey],
      6,
    );
    normalized[reservedOutputCharsKey] = _intValue(
      normalized[reservedOutputCharsKey],
      reservedOutputTokens,
    );
    return normalized;
  }

  JsonMap runtimeStrategySettings(JsonMap raw) {
    // 中文注释: 运行时策略只消费 token 压力字段，但继续携带旧字段，方便还没迁完的调用点渐进过渡。
    final normalized = normalizeForStorage(raw);
    return <String, Object?>{
      modelContextWindowTokensKey: normalized[modelContextWindowTokensKey],
      contextWindowHintTokensKey: normalized[contextWindowHintTokensKey],
      warningThresholdRatioKey: normalized[warningThresholdRatioKey],
      criticalThresholdRatioKey: normalized[criticalThresholdRatioKey],
      reservedOutputTokensKey: normalized[reservedOutputTokensKey],
      autoCompactPolicyKey: normalized[autoCompactPolicyKey],
      preferExactCountKey: normalized[preferExactCountKey],
      compactionOutputPolicyKey: normalized[compactionOutputPolicyKey],
      compressionThresholdPercentKey:
          normalized[compressionThresholdPercentKey],
      contextPackBudgetPercentKey: normalized[contextPackBudgetPercentKey],
      maxContextFileCharsKey: normalized[maxContextFileCharsKey],
      maxContextFilesPerKindKey: normalized[maxContextFilesPerKindKey],
      reservedOutputCharsKey: normalized[reservedOutputCharsKey],
    };
  }

  int _modelWindowTokens(JsonMap settings) {
    // 中文注释: 模型窗口优先取正式 token 字段，没有时再回退到旧字段或保守默认值。
    return _intValue(
      settings[modelContextWindowTokensKey],
      _intValue(settings[contextWindowHintTokensKey], 100000),
    );
  }

  int _hintWindowTokens(JsonMap settings, int fallback) {
    // 中文注释: 窗口提示只是辅助值，缺省时直接跟随正式窗口，避免出现两套彼此矛盾的口径。
    return _intValue(settings[contextWindowHintTokensKey], fallback);
  }

  double _warningRatio(JsonMap settings) {
    // 中文注释: 预警阈值优先读 token 时代的 ratio 字段，旧百分比只作为兼容输入。
    final raw = settings[warningThresholdRatioKey];
    if (raw != null) {
      return _clampRatio(ValueReaders.doubleValue(raw, 0.8));
    }
    return _percentToRatio(settings[compressionThresholdPercentKey], 0.8);
  }

  double _criticalRatio(JsonMap settings, double warningRatio) {
    // 中文注释: 临界阈值必须不低于预警阈值，避免 UI 和运行时都出现反向阈值。
    final raw = settings[criticalThresholdRatioKey];
    final critical = raw != null
        ? _clampRatio(ValueReaders.doubleValue(raw, 0.95))
        : 0.95;
    return critical < warningRatio ? warningRatio : critical;
  }

  int _reservedOutputTokens(JsonMap settings) {
    // 中文注释: 输出保留量迁移到 token 口径后，保留旧字符字段作回退值。
    return _intValue(
      settings[reservedOutputTokensKey],
      _intValue(settings[reservedOutputCharsKey], 2048),
    );
  }

  int _intValue(Object? value, int fallback) {
    // 中文注释: 这里集中处理设置里常见的字符串数字，避免 UI 和控制器重复写解析。
    return ValueReaders.intValue(value, fallback);
  }

  String _stringValue(Object? value, String fallback) {
    // 中文注释: 字符串字段统一去空，方便下游直接使用而不用重复 trim。
    final text = ValueReaders.stringValue(value).trim();
    return text.isEmpty ? fallback : text;
  }

  double _percentToRatio(Object? value, double fallback) {
    // 中文注释: 旧百分比设置要转换成 ratio，确保内部策略层只看 token 时代的比例合同。
    final percent = ValueReaders.doubleValue(value, fallback * 100);
    return _clampRatio(percent / 100);
  }

  int _percentFromRatio(double ratio) {
    // 中文注释: 保存兼容桥时，把内部 ratio 再投影回百分比，方便旧逻辑继续读到熟悉的字段。
    return (ratio * 100).round().clamp(0, 100).toInt();
  }

  double _clampRatio(double value) {
    // 中文注释: ratio 统一钳制在 0 到 1 之间，避免设置写错后把压力判断推到异常区间。
    if (value.isNaN || value.isInfinite) {
      return 0.8;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }
}
