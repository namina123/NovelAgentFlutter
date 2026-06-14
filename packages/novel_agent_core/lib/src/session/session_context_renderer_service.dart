import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_compaction_prompt_contracts.dart';
import 'session_context_pressure_contracts.dart';
import 'session_message_service.dart';
import 'session_mode_service.dart';
import 'session_record_constants.dart';
import 'session_record_normalizer_service.dart';

class SessionContextRendererService {
  SessionContextRendererService({
    required SessionRecordNormalizerService normalizerService,
    required SessionMessageService messageService,
    required SessionModeService modeService,
  }) : _normalizerService = normalizerService,
       _messageService = messageService,
       _modeService = modeService;

  final SessionRecordNormalizerService _normalizerService;
  final SessionMessageService _messageService;
  final SessionModeService _modeService;

  String sessionContextMarkdown(
    JsonMap session, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 会话上下文渲染只负责把稳定合同投影成模型可读 Markdown，不在这里重算压缩或压力判断。
    final normalized = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
    final lines = <String>[
      '【会话状态】',
      '目标：${ValueReaders.stringValue(normalized['title'], '新会话')}',
      '模式：${ValueReaders.stringValue(normalized['mode'], SessionRecordConstants.modeSmartOpening)}',
      '内部阶段：${ValueReaders.stringValue(normalized['workflow_stage'], 'opening')}',
      '公开状态：${ValueReaders.stringValue(normalized['public_status'], '准备中')}',
    ];
    final pressureSnapshot = _pressureSnapshotFromOptions(options);
    if (pressureSnapshot != null) {
      lines.add('');
      lines.add('【上下文压力】');
      lines.add(_pressureSummaryLine(pressureSnapshot));
    }
    final guidanceBlock = _compactionGuidanceBlockFromOptions(options);
    if (guidanceBlock.isNotEmpty) {
      lines.add('');
      lines.add('【压缩指导】');
      lines.addAll(guidanceBlock);
    }
    final compactionArchiveLines = _compactionArchiveLines(normalized);
    if (compactionArchiveLines.isNotEmpty) {
      lines.add('');
      lines.add('【压缩归档】');
      lines.addAll(compactionArchiveLines);
    }
    final pinnedRefs = ValueReaders.stringList(
      normalized[SessionRecordConstants.pinnedContextRefsField],
    );
    if (pinnedRefs.isNotEmpty) {
      lines.add('');
      lines.add('【固定引用】');
      for (final ref in pinnedRefs) {
        lines.add('- $ref');
      }
    }
    final messages = _messageService.messagesForContext(
      _messageService.normalizeMessages(
        normalized[SessionRecordConstants.workingContextMessagesField],
      ),
      excludeLatestUserContent: ValueReaders.stringValue(
        options['exclude_latest_user_content'],
      ),
    );
    if (messages.isNotEmpty) {
      lines.add('');
      lines.add('【工作上下文】');
    }
    for (final message in messages) {
      lines.add(
        '${ValueReaders.stringValue(message['role'], 'user')}: ${ValueReaders.stringValue(message['content'])}',
      );
    }
    return lines.join('\n');
  }

  String sessionPublicSummary(
    JsonMap session, {
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 公开摘要改成 token / pressure 口径，避免列表页继续暴露字符阈值。
    if (session.isEmpty) {
      return '无会话';
    }
    final normalized = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: defaultThresholdChars,
    );
    final pressureSnapshot = _pressureSnapshotFromOptions(options);
    final archiveCount = ValueReaders.intValue(
      normalized[SessionRecordConstants.compressionCountField],
    );
    final workingCount = ValueReaders.objectList(
      normalized[SessionRecordConstants.workingContextMessagesField],
    ).length;
    if (pressureSnapshot == null) {
      return '压力 未配置｜工作消息 $workingCount 条｜压缩 $archiveCount 段';
    }
    final estimate = pressureSnapshot.estimate;
    return '压力 ${pressureSnapshot.pressureLevel.toJsonValue()}｜已用 ${estimate.totalInputTokens} / ${pressureSnapshot.inputBudgetTokens} token｜剩余 ${pressureSnapshot.remainingInputTokens} token｜来源 ${estimate.countSource.toJsonValue()}｜压缩 $archiveCount 段';
  }

  SessionContextPressureSnapshot? _pressureSnapshotFromOptions(
    JsonMap options,
  ) {
    // 中文注释: 压力快照只在调用方显式提供时参与渲染，renderer 本身不重算 token。
    final raw = options['pressure_snapshot'];
    if (raw == null) {
      return null;
    }
    if (raw is SessionContextPressureSnapshot) {
      return raw;
    }
    final rawMap = ValueReaders.mapValue(raw);
    if (rawMap.isEmpty) {
      return null;
    }
    return SessionContextPressureSnapshot.fromJson(rawMap);
  }

  List<String> _compactionGuidanceBlockFromOptions(JsonMap options) {
    // 中文注释: 压缩指导块只投影稳定合同，不把真实用户提示词塞进这个层里。
    final guidance = _compactionGuidanceFromOptions(options);
    if (guidance == null) {
      return const <String>[];
    }
    final lines = <String>['指导：${guidance.title}', '摘要：${guidance.summary}'];
    if (guidance.rules.isNotEmpty) {
      lines.add('规则：');
      for (final rule in guidance.rules) {
        lines.add('- $rule');
      }
    }
    final outputPolicy = _compactionOutputPolicyFromOptions(options);
    if (outputPolicy != null) {
      lines.add(
        '输出：${outputPolicy.title}｜格式 ${outputPolicy.outputFormat}｜上限 ${outputPolicy.maxCharacters > 0 ? '${outputPolicy.maxCharacters} 字' : '未设字数上限'}｜条数 ${outputPolicy.maxBulletCount > 0 ? '${outputPolicy.maxBulletCount} 条' : '未设条数上限'}',
      );
    }
    final sourceScope = _compactionSourceScopeFromOptions(options);
    if (sourceScope != null) {
      lines.add(
        '来源：${sourceScope.scopeId}${sourceScope.sourceKinds.isEmpty ? '' : '｜${sourceScope.sourceKinds.join(', ')}'}',
      );
      if (sourceScope.excludedSourceKinds.isNotEmpty) {
        lines.add('排除：${sourceScope.excludedSourceKinds.join(', ')}');
      }
    }
    final runtimeInstruction = _runtimeContinuationInstructionFromOptions(
      options,
    );
    if (runtimeInstruction != null) {
      lines.add('续跑：${runtimeInstruction.title}');
      lines.add(runtimeInstruction.instruction);
    }
    return lines;
  }

  CompactionGuidanceContract? _compactionGuidanceFromOptions(JsonMap options) {
    // 中文注释: 既支持直接传合同对象，也支持传其 JSON 形态，便于 app / test 侧复用同一入口。
    final raw = options['compaction_guidance'];
    if (raw == null) {
      return null;
    }
    if (raw is CompactionGuidanceContract) {
      return raw;
    }
    final rawMap = ValueReaders.mapValue(raw);
    if (rawMap.isEmpty) {
      return null;
    }
    return CompactionGuidanceContract.fromJson(rawMap);
  }

  CompactionOutputPolicy? _compactionOutputPolicyFromOptions(JsonMap options) {
    // 中文注释: 输出政策是压缩指导块的一部分，但只在调用方提供时渲染。
    final raw = options['compaction_output_policy'];
    if (raw == null) {
      return null;
    }
    if (raw is CompactionOutputPolicy) {
      return raw;
    }
    final rawMap = ValueReaders.mapValue(raw);
    if (rawMap.isEmpty) {
      return null;
    }
    return CompactionOutputPolicy.fromJson(rawMap);
  }

  CompactionSourceScope? _compactionSourceScopeFromOptions(JsonMap options) {
    // 中文注释: 来源范围负责说明压缩可看哪些来源，不和 guidance 或 output policy 混在一起。
    final raw = options['compaction_source_scope'];
    if (raw == null) {
      return null;
    }
    if (raw is CompactionSourceScope) {
      return raw;
    }
    final rawMap = ValueReaders.mapValue(raw);
    if (rawMap.isEmpty) {
      return null;
    }
    return CompactionSourceScope.fromJson(rawMap);
  }

  RuntimeContinuationInstructionContract?
  _runtimeContinuationInstructionFromOptions(JsonMap options) {
    // 中文注释: 内部续跑指令和真实用户提示词分层，只有调用方显式提供才展示。
    final raw = options['runtime_continuation_instruction'];
    if (raw == null) {
      return null;
    }
    if (raw is RuntimeContinuationInstructionContract) {
      return raw;
    }
    final rawMap = ValueReaders.mapValue(raw);
    if (rawMap.isEmpty) {
      return null;
    }
    return RuntimeContinuationInstructionContract.fromJson(rawMap);
  }

  List<String> _compactionArchiveLines(JsonMap normalized) {
    // 中文注释: 压缩归档直接消费结构化 segments，保证 renderer 看见的是 archive 事实而不是单串摘要。
    final segments = ValueReaders.mapList(
      normalized[SessionRecordConstants.compactionSegmentsField],
    );
    if (segments.isEmpty) {
      return const <String>[];
    }
    final lines = <String>[];
    for (final segment in segments) {
      final title = ValueReaders.stringValue(segment['title']).trim();
      final summary = ValueReaders.stringValue(segment['summary']).trim();
      final sourceCount = ValueReaders.intValue(
        segment['source_message_count'],
      );
      final sources = ValueReaders.stringList(segment['source_message_roles']);
      if (title.isEmpty && summary.isEmpty) {
        continue;
      }
      final headerParts = <String>[];
      if (title.isNotEmpty) {
        headerParts.add(title);
      }
      if (sourceCount > 0) {
        headerParts.add('来源 $sourceCount 条');
      }
      if (sources.isNotEmpty) {
        headerParts.add('角色 ${sources.join(', ')}');
      }
      lines.add('- ${headerParts.join('｜')}');
      if (summary.isNotEmpty) {
        lines.add(summary);
      }
    }
    return lines;
  }

  String _pressureSummaryLine(SessionContextPressureSnapshot snapshot) {
    // 中文注释: 压力摘要以 token / pressure 口径输出，供模型输入和公开摘要共享。
    final estimate = snapshot.estimate;
    return '压力 ${snapshot.pressureLevel.toJsonValue()}｜已用 ${estimate.totalInputTokens} / ${snapshot.inputBudgetTokens} token｜剩余 ${snapshot.remainingInputTokens} token｜来源 ${estimate.countSource.toJsonValue()}';
  }
}
