import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_context_pressure_enums.dart';

class SessionTokenBudgetSettings {
  SessionTokenBudgetSettings({
    required int modelContextWindowTokens,
    required int reservedOutputTokens,
    double warningThresholdRatio = 0.8,
    double criticalThresholdRatio = 0.95,
  }) : modelContextWindowTokens = modelContextWindowTokens < 0
           ? 0
           : modelContextWindowTokens,
       reservedOutputTokens = reservedOutputTokens < 0
           ? 0
           : reservedOutputTokens,
       warningThresholdRatio = _normalizeThresholdRatio(warningThresholdRatio),
       criticalThresholdRatio = _normalizeCriticalThresholdRatio(
         warningThresholdRatio,
         criticalThresholdRatio,
       );

  final int modelContextWindowTokens;
  final int reservedOutputTokens;
  final double warningThresholdRatio;
  final double criticalThresholdRatio;

  @override
  bool operator ==(Object other) {
    // 中文注释: 这些 contract 是纯值对象，必须支持稳定值比较，方便测试和上层快照缓存。
    return other is SessionTokenBudgetSettings &&
        other.modelContextWindowTokens == modelContextWindowTokens &&
        other.reservedOutputTokens == reservedOutputTokens &&
        other.warningThresholdRatio == warningThresholdRatio &&
        other.criticalThresholdRatio == criticalThresholdRatio;
  }

  @override
  int get hashCode {
    // 中文注释: hashCode 与值语义绑定，避免 contract 放入集合或缓存时出现不一致。
    return Object.hash(
      modelContextWindowTokens,
      reservedOutputTokens,
      warningThresholdRatio,
      criticalThresholdRatio,
    );
  }

  int get inputBudgetTokens {
    // 中文注释: 输入预算把输出保留量先扣掉，后续压力判断只看真正可占用的窗口。
    final budget = modelContextWindowTokens - reservedOutputTokens;
    return budget < 0 ? 0 : budget;
  }

  int get warningThresholdTokens {
    // 中文注释: 提前把比例换成 token 阈值，方便后续快照与展示层复用同一口径。
    return (inputBudgetTokens * warningThresholdRatio).floor();
  }

  int get criticalThresholdTokens {
    // 中文注释: critical 阈值同样只由比例和输入预算推导，不在外部重复维护另一套数字。
    return (inputBudgetTokens * criticalThresholdRatio).floor();
  }

  JsonMap toJson() {
    // 中文注释: 设置对象只输出稳定字段名，避免将来 token 压力口径再迁移时引入旧字符命名。
    return <String, Object?>{
      'model_context_window_tokens': modelContextWindowTokens,
      'reserved_output_tokens': reservedOutputTokens,
      'warning_threshold_ratio': warningThresholdRatio,
      'critical_threshold_ratio': criticalThresholdRatio,
    };
  }

  factory SessionTokenBudgetSettings.fromJson(JsonMap json) {
    // 中文注释: 这里负责把外部 Map 收敛成稳定设置合同，缺省值走保守默认，不依赖字符阈值字段。
    return SessionTokenBudgetSettings(
      modelContextWindowTokens: ValueReaders.intValue(
        json['model_context_window_tokens'],
      ),
      reservedOutputTokens: ValueReaders.intValue(
        json['reserved_output_tokens'],
      ),
      warningThresholdRatio: ValueReaders.doubleValue(
        json['warning_threshold_ratio'],
        0.8,
      ),
      criticalThresholdRatio: ValueReaders.doubleValue(
        json['critical_threshold_ratio'],
        0.95,
      ),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 基础校验只报告明显不合理的预算参数，方便后续服务在进入重型计算前提前拦截。
    final issues = <String>[];
    if (modelContextWindowTokens <= 0) {
      issues.add('missing_model_context_window_tokens');
    }
    if (warningThresholdRatio <= 0 || warningThresholdRatio >= 1) {
      issues.add('invalid_warning_threshold_ratio');
    }
    if (criticalThresholdRatio <= 0 || criticalThresholdRatio >= 1) {
      issues.add('invalid_critical_threshold_ratio');
    }
    if (criticalThresholdRatio < warningThresholdRatio) {
      issues.add('critical_threshold_ratio_below_warning_threshold_ratio');
    }
    return issues;
  }

  static double _normalizeThresholdRatio(double raw) {
    // 中文注释: 比例值统一限制在 0 到 1 之间，避免配置写错后把压力判断推到异常区间。
    if (raw.isNaN || raw.isInfinite) {
      return 0.8;
    }
    if (raw < 0) {
      return 0;
    }
    if (raw > 1) {
      return 1;
    }
    return raw;
  }

  static double _normalizeCriticalThresholdRatio(
    double warningRatio,
    double criticalRatio,
  ) {
    // 中文注释: critical 必须不低于 warning，保证压力等级是单调递进的而不是反向跳变。
    final normalizedWarning = _normalizeThresholdRatio(warningRatio);
    final normalizedCritical = _normalizeThresholdRatio(criticalRatio);
    return normalizedCritical < normalizedWarning
        ? normalizedWarning
        : normalizedCritical;
  }
}

class SessionTokenBudgetEstimate {
  SessionTokenBudgetEstimate({
    required int systemPromptTokens,
    required int messageTokens,
    int framingTokens = 0,
    int? providerExactCountHintTokens,
    SessionTokenCountSource countSource =
        SessionTokenCountSource.conservativeEstimate,
  }) : systemPromptTokens = systemPromptTokens < 0 ? 0 : systemPromptTokens,
       messageTokens = messageTokens < 0 ? 0 : messageTokens,
       framingTokens = framingTokens < 0 ? 0 : framingTokens,
       countSource = countSource,
       providerExactCountHintTokens = _normalizeOptionalNonNegative(
         providerExactCountHintTokens,
       );

  final int systemPromptTokens;
  final int messageTokens;
  final int framingTokens;
  final int? providerExactCountHintTokens;
  final SessionTokenCountSource countSource;

  @override
  bool operator ==(Object other) {
    // 中文注释: 估算结果也是纯值对象，必须允许直接比较以便 contract 测试与快照断言。
    return other is SessionTokenBudgetEstimate &&
        other.systemPromptTokens == systemPromptTokens &&
        other.messageTokens == messageTokens &&
        other.framingTokens == framingTokens &&
        other.providerExactCountHintTokens == providerExactCountHintTokens &&
        other.countSource == countSource;
  }

  @override
  int get hashCode {
    // 中文注释: 估算对象的 hashCode 只依赖于稳定字段，保证 round-trip 后集合语义一致。
    return Object.hash(
      systemPromptTokens,
      messageTokens,
      framingTokens,
      providerExactCountHintTokens,
      countSource,
    );
  }

  int get totalInputTokens {
    // 中文注释: 总输入 token 由系统提示、消息内容和少量 framing overhead 组成，便于后续统一做压力判断。
    return systemPromptTokens + messageTokens + framingTokens;
  }

  JsonMap toJson() {
    // 中文注释: 估算对象直接输出 token 口径字段，不再沿用字符阈值命名或隐式计算。
    final result = <String, Object?>{
      'system_prompt_tokens': systemPromptTokens,
      'message_tokens': messageTokens,
      'framing_tokens': framingTokens,
      'total_input_tokens': totalInputTokens,
      'token_count_source': countSource.toJsonValue(),
    };
    if (providerExactCountHintTokens != null) {
      result['provider_exact_count_hint_tokens'] = providerExactCountHintTokens;
    }
    return result;
  }

  factory SessionTokenBudgetEstimate.fromJson(JsonMap json) {
    // 中文注释: 从 Map 读回时保留同一 token 估算合同，未知来源默认回落到保守估算。
    return SessionTokenBudgetEstimate(
      systemPromptTokens: ValueReaders.intValue(json['system_prompt_tokens']),
      messageTokens: ValueReaders.intValue(json['message_tokens']),
      framingTokens: ValueReaders.intValue(json['framing_tokens']),
      providerExactCountHintTokens:
          json.containsKey('provider_exact_count_hint_tokens')
          ? ValueReaders.intValue(json['provider_exact_count_hint_tokens'])
          : null,
      countSource: SessionTokenCountSource.fromJsonValue(
        json['token_count_source'],
      ),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 估算结果只校验最基础的非负约束，避免负 token 这种脏数据继续向下游传播。
    final issues = <String>[];
    if (systemPromptTokens < 0) {
      issues.add('negative_system_prompt_tokens');
    }
    if (messageTokens < 0) {
      issues.add('negative_message_tokens');
    }
    if (framingTokens < 0) {
      issues.add('negative_framing_tokens');
    }
    if (providerExactCountHintTokens != null &&
        providerExactCountHintTokens! < 0) {
      issues.add('negative_provider_exact_count_hint_tokens');
    }
    return issues;
  }

  static int? _normalizeOptionalNonNegative(int? raw) {
    // 中文注释: 可选 hint 只在存在时参与归一化，负值直接收敛成零，避免下游收到反直觉 token 数。
    if (raw == null) {
      return null;
    }
    return raw < 0 ? 0 : raw;
  }
}

class SessionContextPressureSnapshot {
  SessionContextPressureSnapshot({
    required this.settings,
    required this.estimate,
    SessionContextPressureLevel? pressureLevel,
  }) : pressureLevel =
           pressureLevel ??
           _resolvePressureLevel(settings: settings, estimate: estimate);

  final SessionTokenBudgetSettings settings;
  final SessionTokenBudgetEstimate estimate;
  final SessionContextPressureLevel pressureLevel;

  @override
  bool operator ==(Object other) {
    // 中文注释: 快照是发送前的唯一事实源，也应该支持值比较，方便恢复测试和 pressure 断言。
    return other is SessionContextPressureSnapshot &&
        other.settings == settings &&
        other.estimate == estimate &&
        other.pressureLevel == pressureLevel;
  }

  @override
  int get hashCode {
    // 中文注释: 快照 hashCode 绑定 settings、estimate 与等级，保证缓存和集合行为一致。
    return Object.hash(settings, estimate, pressureLevel);
  }

  int get inputBudgetTokens {
    // 中文注释: 快照里的输入预算直接复用 settings 的结果，保证压力判断和设置来源完全同源。
    return settings.inputBudgetTokens;
  }

  int get remainingInputTokens {
    // 中文注释: 剩余 token 采用“预算减去实际输入”的单一路径，避免 GUI 和核心各算各的。
    return inputBudgetTokens - estimate.totalInputTokens;
  }

  int get overflowTokens {
    // 中文注释: overflow 只在越界时返回正数，便于后续把 critical 与 over_limit 区分开来。
    return remainingInputTokens < 0 ? -remainingInputTokens : 0;
  }

  double get usedContextRatio {
    // 中文注释: 使用率是一个稳定的无量纲指标，便于 warning/critical 在不同窗口大小下保持一致。
    if (inputBudgetTokens <= 0) {
      return estimate.totalInputTokens > 0 ? 1 : 0;
    }
    return estimate.totalInputTokens / inputBudgetTokens;
  }

  bool get hasOverflow {
    // 中文注释: 是否越界是 pressure level 的基础事实，后续续跑前判断可以直接复用这个布尔值。
    return overflowTokens > 0;
  }

  JsonMap toJson() {
    // 中文注释: 压力快照把 settings、estimate 和派生指标一起打包，形成发送前判断的唯一事实源。
    return <String, Object?>{
      'settings': settings.toJson(),
      'estimate': estimate.toJson(),
      'pressure_level': pressureLevel.toJsonValue(),
      'input_budget_tokens': inputBudgetTokens,
      'remaining_input_tokens': remainingInputTokens,
      'overflow_tokens': overflowTokens,
      'used_context_ratio': usedContextRatio,
      'has_overflow': hasOverflow,
    };
  }

  factory SessionContextPressureSnapshot.fromJson(JsonMap json) {
    // 中文注释: 快照反序列化优先恢复嵌套 contract，再在缺省状态下按同一规则推导 pressure level。
    final settings = SessionTokenBudgetSettings.fromJson(
      ValueReaders.mapValue(json['settings']),
    );
    final estimate = SessionTokenBudgetEstimate.fromJson(
      ValueReaders.mapValue(json['estimate']),
    );
    final explicitPressureLevel = json.containsKey('pressure_level')
        ? SessionContextPressureLevel.fromJsonValue(json['pressure_level'])
        : null;
    return SessionContextPressureSnapshot(
      settings: settings,
      estimate: estimate,
      pressureLevel: explicitPressureLevel,
    );
  }

  List<String> validateBasics() {
    // 中文注释: 快照只做浅层合同校验，再把更细的参数检查交回 settings 和 estimate。
    final issues = <String>[];
    issues.addAll(settings.validateBasics());
    issues.addAll(estimate.validateBasics());
    return issues;
  }

  static SessionContextPressureLevel _resolvePressureLevel({
    required SessionTokenBudgetSettings settings,
    required SessionTokenBudgetEstimate estimate,
  }) {
    // 中文注释: 压力等级严格按照“越界优先、临界其次、预警再次、其余安全”的顺序推导。
    final remaining = settings.inputBudgetTokens - estimate.totalInputTokens;
    if (remaining < 0) {
      return SessionContextPressureLevel.overLimit;
    }
    final ratio = settings.inputBudgetTokens <= 0
        ? (estimate.totalInputTokens > 0 ? 1.0 : 0.0)
        : estimate.totalInputTokens / settings.inputBudgetTokens;
    if (ratio >= settings.criticalThresholdRatio) {
      return SessionContextPressureLevel.critical;
    }
    if (ratio >= settings.warningThresholdRatio) {
      return SessionContextPressureLevel.warning;
    }
    return SessionContextPressureLevel.safe;
  }
}
