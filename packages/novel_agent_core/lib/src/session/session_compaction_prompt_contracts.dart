import '../common/json_types.dart';
import '../common/value_readers.dart';

enum CompactionPromptInjectionSectionKind {
  systemFoundation,
  projectGuidance,
  compactionGuidance,
  contextPayload,
  currentUserPrompt,
  runtimeContinuationInstruction;

  String toJsonValue() {
    // 中文注释: 注入顺序的分段标识必须保持稳定，方便后续 prompt 组装与测试直接对齐。
    return switch (this) {
      CompactionPromptInjectionSectionKind.systemFoundation =>
        'system_foundation',
      CompactionPromptInjectionSectionKind.projectGuidance =>
        'project_guidance',
      CompactionPromptInjectionSectionKind.compactionGuidance =>
        'compaction_guidance',
      CompactionPromptInjectionSectionKind.contextPayload => 'context_payload',
      CompactionPromptInjectionSectionKind.currentUserPrompt =>
        'current_user_prompt',
      CompactionPromptInjectionSectionKind.runtimeContinuationInstruction =>
        'runtime_continuation_instruction',
    };
  }

  static CompactionPromptInjectionSectionKind fromJsonValue(Object? raw) {
    // 中文注释: 未识别的分段标识不参与拼装，默认回落到 current_user_prompt，避免污染上游顺序。
    final normalized = ValueReaders.stringValue(raw).trim().toLowerCase();
    return switch (normalized) {
      'system_foundation' =>
        CompactionPromptInjectionSectionKind.systemFoundation,
      'project_guidance' =>
        CompactionPromptInjectionSectionKind.projectGuidance,
      'compaction_guidance' =>
        CompactionPromptInjectionSectionKind.compactionGuidance,
      'context_payload' => CompactionPromptInjectionSectionKind.contextPayload,
      'runtime_continuation_instruction' =>
        CompactionPromptInjectionSectionKind.runtimeContinuationInstruction,
      _ => CompactionPromptInjectionSectionKind.currentUserPrompt,
    };
  }
}

class CompactionGuidanceContract {
  const CompactionGuidanceContract({
    required this.guidanceId,
    required this.title,
    required this.summary,
    this.rules = const <String>[],
    this.sourceScopeId = '',
    this.outputPolicyId = '',
    this.metadata = const <String, Object?>{},
  });

  final String guidanceId;
  final String title;
  final String summary;
  final List<String> rules;
  final String sourceScopeId;
  final String outputPolicyId;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: guidance 合同只输出分层字段，不把输出政策和源范围压成一个散 prompt。
    return <String, Object?>{
      'guidance_id': guidanceId,
      'title': title,
      'summary': summary,
      'rules': rules,
      'source_scope_id': sourceScopeId,
      'output_policy_id': outputPolicyId,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  factory CompactionGuidanceContract.fromJson(JsonMap json) {
    // 中文注释: guidance 反序列化保留原始规则列表和关联 ID，供后续 prompt 组装复用。
    return CompactionGuidanceContract(
      guidanceId: ValueReaders.stringValue(json['guidance_id']),
      title: ValueReaders.stringValue(json['title']),
      summary: ValueReaders.stringValue(json['summary']),
      rules: ValueReaders.stringList(json['rules']),
      sourceScopeId: ValueReaders.stringValue(json['source_scope_id']),
      outputPolicyId: ValueReaders.stringValue(json['output_policy_id']),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: guidance 基础校验只看最核心的标识与摘要，避免空壳 guidance 进入协议层。
    final issues = <String>[];
    if (guidanceId.trim().isEmpty) {
      issues.add('missing_compaction_guidance_id');
    }
    if (summary.trim().isEmpty) {
      issues.add('missing_compaction_guidance_summary');
    }
    return issues;
  }
}

class CompactionOutputPolicy {
  const CompactionOutputPolicy({
    required this.policyId,
    required this.title,
    this.outputFormat = 'structured_bullets',
    this.maxCharacters = 0,
    this.maxBulletCount = 0,
    this.preservePinnedFacts = true,
    this.preserveSourceAttribution = true,
    this.preferUnknownMarkers = true,
    this.metadata = const <String, Object?>{},
  });

  final String policyId;
  final String title;
  final String outputFormat;
  final int maxCharacters;
  final int maxBulletCount;
  final bool preservePinnedFacts;
  final bool preserveSourceAttribution;
  final bool preferUnknownMarkers;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: output policy 只描述压缩输出应长什么样，不承载源范围或续跑指令。
    return <String, Object?>{
      'policy_id': policyId,
      'title': title,
      'output_format': outputFormat,
      'max_characters': maxCharacters,
      'max_bullet_count': maxBulletCount,
      'preserve_pinned_facts': preservePinnedFacts,
      'preserve_source_attribution': preserveSourceAttribution,
      'prefer_unknown_markers': preferUnknownMarkers,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  factory CompactionOutputPolicy.fromJson(JsonMap json) {
    // 中文注释: 输出政策反序列化只恢复格式与长度边界，避免误把其他层的信息混进来。
    return CompactionOutputPolicy(
      policyId: ValueReaders.stringValue(json['policy_id']),
      title: ValueReaders.stringValue(json['title']),
      outputFormat: ValueReaders.stringValue(
        json['output_format'],
        'structured_bullets',
      ),
      maxCharacters: ValueReaders.intValue(json['max_characters']),
      maxBulletCount: ValueReaders.intValue(json['max_bullet_count']),
      preservePinnedFacts: ValueReaders.boolValue(
        json['preserve_pinned_facts'],
        true,
      ),
      preserveSourceAttribution: ValueReaders.boolValue(
        json['preserve_source_attribution'],
        true,
      ),
      preferUnknownMarkers: ValueReaders.boolValue(
        json['prefer_unknown_markers'],
        true,
      ),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 输出政策只校验格式和标识，允许长度值为 0 表示由上层默认策略接管。
    final issues = <String>[];
    if (policyId.trim().isEmpty) {
      issues.add('missing_compaction_output_policy_id');
    }
    if (title.trim().isEmpty) {
      issues.add('missing_compaction_output_policy_title');
    }
    return issues;
  }
}

class CompactionSourceScope {
  const CompactionSourceScope({
    required this.scopeId,
    this.sourceKinds = const <String>[],
    this.excludedSourceKinds = const <String>[],
    this.allowLegacyContextBridge = true,
    this.allowCurrentUserPrompt = true,
    this.allowRuntimeContinuationInstruction = true,
    this.metadata = const <String, Object?>{},
  });

  final String scopeId;
  final List<String> sourceKinds;
  final List<String> excludedSourceKinds;
  final bool allowLegacyContextBridge;
  final bool allowCurrentUserPrompt;
  final bool allowRuntimeContinuationInstruction;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: source scope 只描述哪些来源可参与压缩，不承载输出样式或指导文本。
    return <String, Object?>{
      'scope_id': scopeId,
      'source_kinds': sourceKinds,
      'excluded_source_kinds': excludedSourceKinds,
      'allow_legacy_context_bridge': allowLegacyContextBridge,
      'allow_current_user_prompt': allowCurrentUserPrompt,
      'allow_runtime_continuation_instruction':
          allowRuntimeContinuationInstruction,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  factory CompactionSourceScope.fromJson(JsonMap json) {
    // 中文注释: 源范围反序列化优先恢复允许/排除集合，方便后续发送前压缩直接复用。
    return CompactionSourceScope(
      scopeId: ValueReaders.stringValue(json['scope_id']),
      sourceKinds: ValueReaders.stringList(json['source_kinds']),
      excludedSourceKinds: ValueReaders.stringList(
        json['excluded_source_kinds'],
      ),
      allowLegacyContextBridge: ValueReaders.boolValue(
        json['allow_legacy_context_bridge'],
        true,
      ),
      allowCurrentUserPrompt: ValueReaders.boolValue(
        json['allow_current_user_prompt'],
        true,
      ),
      allowRuntimeContinuationInstruction: ValueReaders.boolValue(
        json['allow_runtime_continuation_instruction'],
        true,
      ),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 源范围至少要有一个 scopeId，才能在后续协议里被准确引用。
    final issues = <String>[];
    if (scopeId.trim().isEmpty) {
      issues.add('missing_compaction_source_scope_id');
    }
    return issues;
  }
}

class RuntimeContinuationInstructionContract {
  const RuntimeContinuationInstructionContract({
    required this.instructionId,
    required this.title,
    required this.instruction,
    this.triggerKinds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String instructionId;
  final String title;
  final String instruction;
  final List<String> triggerKinds;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: 续跑指令独立成层，避免它和真实用户提示词混成一个 payload。
    return <String, Object?>{
      'instruction_id': instructionId,
      'title': title,
      'instruction': instruction,
      'trigger_kinds': triggerKinds,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  factory RuntimeContinuationInstructionContract.fromJson(JsonMap json) {
    // 中文注释: 续跑指令反序列化保留触发条件，便于恢复时按同一条协议复用。
    return RuntimeContinuationInstructionContract(
      instructionId: ValueReaders.stringValue(json['instruction_id']),
      title: ValueReaders.stringValue(json['title']),
      instruction: ValueReaders.stringValue(json['instruction']),
      triggerKinds: ValueReaders.stringList(json['trigger_kinds']),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 续跑指令至少要有标识和正文，否则只是空壳占位。
    final issues = <String>[];
    if (instructionId.trim().isEmpty) {
      issues.add('missing_runtime_continuation_instruction_id');
    }
    if (instruction.trim().isEmpty) {
      issues.add('missing_runtime_continuation_instruction');
    }
    return issues;
  }
}

class CompactionPromptInjectionFrame {
  const CompactionPromptInjectionFrame({
    required this.systemFoundation,
    required this.projectGuidance,
    required this.compactionGuidance,
    required this.contextPayload,
    required this.currentUserPrompt,
    this.runtimeContinuationInstruction,
    this.metadata = const <String, Object?>{},
  });

  final String systemFoundation;
  final String projectGuidance;
  final CompactionGuidanceContract compactionGuidance;
  final String contextPayload;
  final String currentUserPrompt;
  final RuntimeContinuationInstructionContract? runtimeContinuationInstruction;
  final JsonMap metadata;

  List<CompactionPromptInjectionSectionKind> orderedSectionKinds({
    bool useRuntimeContinuationInstruction = false,
  }) {
    // 中文注释: 注入顺序固定为系统层、项目层、压缩指导、上下文载荷，再按场景选择用户提示或内部续跑指令。
    return <CompactionPromptInjectionSectionKind>[
      CompactionPromptInjectionSectionKind.systemFoundation,
      CompactionPromptInjectionSectionKind.projectGuidance,
      CompactionPromptInjectionSectionKind.compactionGuidance,
      CompactionPromptInjectionSectionKind.contextPayload,
      if (useRuntimeContinuationInstruction &&
          runtimeContinuationInstruction != null)
        CompactionPromptInjectionSectionKind.runtimeContinuationInstruction
      else
        CompactionPromptInjectionSectionKind.currentUserPrompt,
    ];
  }

  JsonMap toJson() {
    // 中文注释: 注入帧只保存分层后的文本与合同，不把 compaction guidance 拼进真实用户 prompt。
    return <String, Object?>{
      'system_foundation': systemFoundation,
      'project_guidance': projectGuidance,
      'compaction_guidance': compactionGuidance.toJson(),
      'context_payload': contextPayload,
      'current_user_prompt': currentUserPrompt,
      'runtime_continuation_instruction': runtimeContinuationInstruction == null
          ? null
          : runtimeContinuationInstruction!.toJson(),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  factory CompactionPromptInjectionFrame.fromJson(JsonMap json) {
    // 中文注释: 注入帧反序列化必须保留用户提示与内部续跑指令的分离边界。
    final rawRuntimeInstruction = ValueReaders.mapValue(
      json['runtime_continuation_instruction'],
    );
    return CompactionPromptInjectionFrame(
      systemFoundation: ValueReaders.stringValue(json['system_foundation']),
      projectGuidance: ValueReaders.stringValue(json['project_guidance']),
      compactionGuidance: CompactionGuidanceContract.fromJson(
        ValueReaders.mapValue(json['compaction_guidance']),
      ),
      contextPayload: ValueReaders.stringValue(json['context_payload']),
      currentUserPrompt: ValueReaders.stringValue(json['current_user_prompt']),
      runtimeContinuationInstruction: rawRuntimeInstruction.isEmpty
          ? null
          : RuntimeContinuationInstructionContract.fromJson(
              rawRuntimeInstruction,
            ),
      metadata: ValueReaders.mapValue(json['metadata']),
    );
  }

  List<String> validateBasics() {
    // 中文注释: 注入帧校验只保证分层字段都在，避免空字符串被误当成已组装好的 prompt。
    final issues = <String>[];
    if (systemFoundation.trim().isEmpty) {
      issues.add('missing_system_foundation');
    }
    if (projectGuidance.trim().isEmpty) {
      issues.add('missing_project_guidance');
    }
    if (contextPayload.trim().isEmpty) {
      issues.add('missing_context_payload');
    }
    if (currentUserPrompt.trim().isEmpty &&
        runtimeContinuationInstruction == null) {
      issues.add('missing_tail_prompt_or_continuation_instruction');
    }
    issues.addAll(compactionGuidance.validateBasics());
    if (runtimeContinuationInstruction != null) {
      issues.addAll(runtimeContinuationInstruction!.validateBasics());
    }
    return issues;
  }
}
