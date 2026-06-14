import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_context_pressure_contracts.dart';
import 'session_context_pressure_enums.dart';
import 'session_record_constants.dart';

class SessionTokenBudgetEstimatorService {
  const SessionTokenBudgetEstimatorService();

  SessionTokenBudgetEstimate estimate({
    String systemPrompt = '',
    List<Object?> messages = const <Object?>[],
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 这里用保守 token 估算把系统提示、消息正文、工具载荷和 framing 开销分开算，供发送前压力判断复用。
    final normalizedMessages = ValueReaders.objectList(messages);
    final cleanSystemPrompt = systemPrompt.trim();
    final systemPromptTokens = estimateSystemPromptTokens(cleanSystemPrompt);
    final messageTokens = estimateMessagesTokens(normalizedMessages);
    final framingTokens = estimateFramingTokens(
      normalizedMessages,
      baseFramingTokens: baseFramingTokens,
    );
    return SessionTokenBudgetEstimate(
      systemPromptTokens: systemPromptTokens,
      messageTokens: messageTokens,
      framingTokens: framingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
      countSource: providerExactCountHintTokens != null
          ? SessionTokenCountSource.providerExactCount
          : SessionTokenCountSource.conservativeEstimate,
    );
  }

  SessionTokenBudgetEstimate estimateFromSessionRecord(
    JsonMap sessionRecord, {
    String systemPrompt = '',
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 这里直接消费 session record 的 working context，避免上层为了估算再自己判断旧字段兼容。
    final messages = _sessionRecordMessages(sessionRecord);
    return estimate(
      systemPrompt: systemPrompt,
      messages: messages,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    );
  }

  int estimateSystemPromptTokens(String systemPrompt) {
    // 中文注释: 系统提示词采用独立的保守估算，并额外保留少量框架开销，避免把系统层吃得过满。
    final clean = systemPrompt.trim();
    if (clean.isEmpty) {
      return 0;
    }
    return estimateTextTokens(clean) + 8;
  }

  int estimateMessagesTokens(List<Object?> messages) {
    // 中文注释: 消息体 token 统计负责把每条消息的正文和结构化字段都纳入，同步覆盖工具调用与工具结果。
    var total = 0;
    for (final message in messages) {
      total += estimateMessageTokens(message);
    }
    return total;
  }

  int estimateMessageTokens(Object? message) {
    // 中文注释: 单条消息按结构化对象递归估算，支持文本、工具调用、工具结果和混合块而不依赖具体 provider 协议。
    return _estimateValueTokens(message);
  }

  int estimateToolPayloadTokens(Object? payload) {
    // 中文注释: 工具载荷独立估算，方便调用方单独观察工具调用是否在明显抬高上下文压力。
    return _estimateValueTokens(payload, toolContext: true);
  }

  int estimateFramingTokens(
    List<Object?> messages, {
    int baseFramingTokens = 12,
  }) {
    // 中文注释: framing 开销只统计消息分隔、角色标记和工具消息额外结构，不把正文内容重复算进来。
    var total = baseFramingTokens < 0 ? 0 : baseFramingTokens;
    final normalizedMessages = ValueReaders.objectList(messages);
    for (final rawMessage in normalizedMessages) {
      total += 2;
      if (_looksLikeToolPayload(rawMessage)) {
        total += 4;
      }
    }
    return total;
  }

  int estimateTextTokens(String text, {bool toolContext = false}) {
    // 中文注释: 文本采用保守字符估算，ASCII 按 4 字一 token，其他字符按 1 字一 token，工具载荷再额外加一点安全边际。
    final clean = text.trim();
    if (clean.isEmpty) {
      return 0;
    }
    var asciiRun = 0;
    var tokens = 0;
    for (final rune in clean.runes) {
      if (_isAsciiRune(rune)) {
        if (_isAsciiSeparator(rune)) {
          tokens += _flushAsciiRun(asciiRun);
          asciiRun = 0;
          continue;
        }
        asciiRun += 1;
        continue;
      }
      tokens += _flushAsciiRun(asciiRun);
      asciiRun = 0;
      tokens += 1;
    }
    tokens += _flushAsciiRun(asciiRun);
    if (tokens <= 0) {
      tokens = 1;
    }
    if (toolContext) {
      tokens += _toolContextBonus(tokens);
    }
    return tokens;
  }

  int _estimateValueTokens(Object? value, {bool toolContext = false}) {
    // 中文注释: 递归估算统一从这一个入口走，保证字符串、列表、字典和工具载荷都被同一套保守规则覆盖。
    if (value == null) {
      return 0;
    }
    if (value is String) {
      return estimateTextTokens(value, toolContext: toolContext);
    }
    if (value is bool || value is num) {
      return 1;
    }
    if (value is List<Object?>) {
      var total = 2;
      for (final item in value) {
        total += _estimateValueTokens(item, toolContext: toolContext);
      }
      return total;
    }
    if (value is List) {
      return _estimateValueTokens(
        List<Object?>.from(value),
        toolContext: toolContext,
      );
    }
    if (value is Map<String, Object?>) {
      return _estimateMapTokens(value, toolContext: toolContext);
    }
    if (value is Map) {
      return _estimateMapTokens(
        ValueReaders.mapValue(value),
        toolContext: toolContext,
      );
    }
    return estimateTextTokens(value.toString(), toolContext: toolContext);
  }

  int _estimateMapTokens(JsonMap map, {required bool toolContext}) {
    // 中文注释: Map 的 key/value 结构会带来额外 framing，因此这里单独给一层字典开销。
    var total = 4;
    for (final entry in map.entries) {
      final key = entry.key.trim();
      if (key.isNotEmpty) {
        total += estimateTextTokens(key);
      } else {
        total += 1;
      }
      final nextToolContext =
          toolContext ||
          _looksLikeToolField(key) ||
          _looksLikeToolPayload(entry.value);
      total += _estimateValueTokens(entry.value, toolContext: nextToolContext);
    }
    return total;
  }

  List<Object?> _sessionRecordMessages(JsonMap sessionRecord) {
    // 中文注释: session record 的消息窗口按 working context 优先读取，旧字段只作为兼容桥，不让估算服务自己重造分裂语义。
    return ValueReaders.objectList(
      sessionRecord[SessionRecordConstants.workingContextMessagesField] ??
          sessionRecord[SessionRecordConstants.legacyContextMessagesField] ??
          sessionRecord[SessionRecordConstants.transcriptMessagesField],
    );
  }

  bool _looksLikeToolPayload(Object? value) {
    // 中文注释: 这里判断值本身是否像工具调用结构，便于把工具结果的嵌套对象按更保守的方式估算。
    if (value is Map<String, Object?>) {
      return value.keys.any(_looksLikeToolField);
    }
    if (value is Map) {
      return ValueReaders.mapValue(value).keys.any(_looksLikeToolField);
    }
    return false;
  }

  bool _looksLikeToolField(String key) {
    // 中文注释: 常见工具载荷字段统一归为工具上下文，避免把 arguments/input/result 这些内容按普通文本轻算。
    final normalized = key.trim().toLowerCase();
    return <String>{
          'tool_calls',
          'tool_use',
          'tool_result',
          'tool_results',
          'tool_payload',
          'tool_call',
          'arguments',
          'input',
          'payload',
          'result',
          'content_blocks',
          'metadata',
        }.contains(normalized) ||
        normalized.startsWith('tool_');
  }

  int _flushAsciiRun(int asciiRun) {
    // 中文注释: ASCII 连续片段按 4 字一 token 估算，保持对英文 prompt、JSON 键名和代码片段的保守性。
    if (asciiRun <= 0) {
      return 0;
    }
    return (asciiRun + 3) ~/ 4;
  }

  bool _isAsciiRune(int rune) {
    // 中文注释: 只把标准 ASCII 当作压缩友好的字符串处理，其余字符都按单字 token 保守计。
    return rune >= 0x20 && rune <= 0x7E;
  }

  bool _isAsciiSeparator(int rune) {
    // 中文注释: 空白字符会打断 ASCII 片段，避免把多段英文短语算得过于乐观。
    return rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D;
  }

  int _toolContextBonus(int rawTokens) {
    // 中文注释: 工具上下文额外加一点安全边际，防止 JSON / arguments / result 的结构成本被低估。
    final bonus = rawTokens ~/ 4;
    return bonus < 2 ? 2 : bonus;
  }
}
