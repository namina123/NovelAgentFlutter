import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'skill_activation_signal.dart';
import 'skill_load_memory.dart';
import 'skill_routing_policy.dart';
import 'stage_skill_preset.dart';

class SkillRoutingPolicyService {
  const SkillRoutingPolicyService();

  SkillActivationSignal buildActivationSignal({
    required String intent,
    required String projectType,
    required String userPrompt,
    JsonMap routeContext = const <String, Object?>{},
  }) {
    // 中文注释: 阶段识别先看宿主显式提供的任务上下文，再用意图和提示词兜底，不把判定写死在单一入口。
    final normalizedIntent = intent.trim().toLowerCase();
    final taskType = ValueReaders.stringValue(
      routeContext['task_type'],
      ValueReaders.stringValue(routeContext['stage']),
    ).trim().toLowerCase();
    final mode = ValueReaders.stringValue(
      routeContext['mode'],
      ValueReaders.stringValue(routeContext['workflow_mode']),
    ).trim();
    final combinedText = <String>[
      userPrompt,
      ValueReaders.stringValue(routeContext['title']),
      ValueReaders.stringValue(routeContext['goal']),
      ValueReaders.stringValue(routeContext['brief']),
    ].where((item) => item.trim().isNotEmpty).join('\n');
    final flags = <String>{
      if (mode.isNotEmpty || normalizedIntent == 'workflow_task') 'long_task',
      if (_containsAny(
        combinedText,
        const <String>['去ai', '自然表达', 'ai味', 'ai 味', 'ai风味', '润色'],
      ))
        'authenticity_pass',
      if (_containsAny(
        combinedText,
        const <String>['连续性', '连贯', '设定', '角色', '伏笔', '时间线', '关系'],
      ))
        'continuity_pressure',
      if (_containsAny(combinedText, const <String>['对白', '对话']))
        'dialogue_pressure',
      if (_containsAny(combinedText, const <String>['悬念', '揭示', '反转']))
        'reveal_pressure',
      if (_containsAny(combinedText, const <String>['标题', '章名']))
        'title_pressure',
      if (_containsAny(combinedText, const <String>['场景', '节奏', '桥段']))
        'scene_pressure',
      if (_containsAny(combinedText, const <String>['总结', '摘要']))
        'summary_pressure',
    }.toList(growable: false);
    return SkillActivationSignal(
      stageId: _resolveStageId(normalizedIntent, taskType, combinedText),
      intent: normalizedIntent,
      taskType: taskType,
      projectType: projectType.trim().toLowerCase(),
      userPrompt: userPrompt,
      mode: mode,
      flags: flags,
      metadata: ValueReaders.deepCopyMap(routeContext),
    );
  }

  SkillRoutingPolicy resolvePolicy(SkillActivationSignal signal) {
    switch (signal.stageId) {
      case 'planning':
        return _planningPolicy(signal);
      case 'review':
        return _reviewPolicy(signal);
      case 'revision':
        return _revisionPolicy(signal);
      case 'chapter_drafting':
        return _chapterDraftingPolicy(signal);
      default:
        return _generalDraftPolicy(signal);
    }
  }

  List<JsonMap> buildPreloadToolCalls(
    SkillRoutingPolicy policy,
    SkillLoadMemory memory,
  ) {
    // 中文注释: 预加载只负责生成缺失摘要的工具调用，不在这里执行工具。
    final calls = <JsonMap>[];
    var index = 0;
    for (final preset in policy.presets) {
      if (memory.hasSummary(preset.skillId) &&
          (preset.preloadDetailLevel != 'full' ||
              memory.hasFull(preset.skillId))) {
        continue;
      }
      calls.add(<String, Object?>{
        'id': 'skill_preload_${policy.stageId}_$index',
        'name': 'load_agent_skill',
        'arguments': <String, Object?>{
          'skill_id': preset.skillId,
          'detail_level': preset.preloadDetailLevel,
        },
      });
      index += 1;
    }
    return calls;
  }

  JsonMap buildPreloadAssistantMessage(
    SkillRoutingPolicy policy,
    List<JsonMap> toolCalls,
  ) {
    // 中文注释: 预加载消息显式带上 tool_calls，让后续网关能把摘要当成真实工具结果继续传递。
    final content =
        '根据当前阶段的技能路由策略，先预加载必要技能摘要：${policy.presets.map((preset) => preset.skillId).join('、')}。';
    return <String, Object?>{
      'role': 'assistant',
      'content': content,
      'tool_calls': toolCalls
          .map(
            (call) => <String, Object?>{
              'id': ValueReaders.stringValue(call['id']),
              'type': 'function',
              'function': <String, Object?>{
                'name': ValueReaders.stringValue(call['name']),
                'arguments': jsonEncode(
                  ValueReaders.mapValue(call['arguments']),
                ),
              },
            },
          )
          .toList(growable: false),
    };
  }

  List<String> buildGuidanceLines(
    SkillRoutingPolicy policy, {
    SkillLoadMemory? skillLoadMemory,
  }) {
    // 中文注释: 技能路由说明独立成结构化文本，宿主可以分别投给长任务提示或常规会话系统提示。
    final lines = <String>[
      '技能路由遵循“先摘要、后按需细读”的阶段策略，不要反复整份读取同一技能。',
    ];
    final loadedMemory = skillLoadMemory;
    final preloadText = policy.presets
        .map((preset) {
          final suffix = loadedMemory != null && loadedMemory.hasSummary(preset.skillId)
              ? '（已预载摘要）'
              : '（应先读摘要）';
          return '${preset.skillId}$suffix';
        })
        .join('、');
    if (preloadText.trim().isNotEmpty) {
      lines.add('当前阶段优先使用的技能：$preloadText。');
    }
    for (final preset in policy.presets) {
      if (preset.referencePaths.isEmpty) {
        continue;
      }
      final referenceText = preset.referencePaths.join('、');
      final reason = preset.reason.trim().isEmpty ? '当前阶段需要更细规则时' : preset.reason.trim();
      lines.add(
        '当$reason，才调用 load_agent_skill 继续读取 ${preset.skillId} 的 reference_path：$referenceText。',
      );
    }
    lines.addAll(policy.notes);
    return lines;
  }

  SkillRoutingPolicy _planningPolicy(SkillActivationSignal signal) {
    return SkillRoutingPolicy(
      stageId: 'planning',
      presets: <StageSkillPreset>[
        const StageSkillPreset(
          skillId: 'generate_outline',
          preloadDetailLevel: 'summary',
          reason: '搭总纲、卷纲、章纲骨架时',
        ),
        const StageSkillPreset(
          skillId: 'novel-control-station',
          preloadDetailLevel: 'summary',
          referencePaths: <String>[
            'references/interview-and-handoff-flow.md',
            'references/character-construction-methods.md',
            'references/graph-and-recall-control.md',
            'references/chapter-architecture-rules.md',
          ],
          reason: '做长篇启动访谈、结构规划与控制面设计时',
        ),
      ],
      notes: const <String>[
        '规划阶段优先先收束方向、角色张力和结构层级，再考虑正文表达。',
      ],
    );
  }

  SkillRoutingPolicy _chapterDraftingPolicy(SkillActivationSignal signal) {
    final references = <String>{
      'references/chapter-architecture-rules.md',
      'references/continuity-and-marathon-mode.md',
    };
    if (signal.hasFlag('scene_pressure')) {
      references.add('references/scene-execution-patterns.md');
    }
    if (signal.hasFlag('dialogue_pressure')) {
      references.add('references/dialogue-writing-rules.md');
    }
    if (signal.hasFlag('reveal_pressure')) {
      references.add('references/suspense-and-reveal-design.md');
    }
    if (signal.hasFlag('title_pressure')) {
      references.add('references/chapter-title-method.md');
    }
    if (signal.hasFlag('continuity_pressure') || signal.hasFlag('long_task')) {
      references
        ..add('references/graph-and-recall-control.md')
        ..add('references/forgotten-elements-and-line-heat.md');
    }
    if (signal.hasFlag('authenticity_pass')) {
      references.add('references/authenticity-and-de-ai-pass.md');
    }
    return SkillRoutingPolicy(
      stageId: 'chapter_drafting',
      presets: <StageSkillPreset>[
        const StageSkillPreset(
          skillId: 'chapter_drafting_method',
          preloadDetailLevel: 'summary',
          reason: '把章纲或场景目标稳定展开为正文时',
        ),
        StageSkillPreset(
          skillId: 'novel-control-station',
          preloadDetailLevel: 'summary',
          referencePaths: references.toList(growable: false),
          reason: '遇到长篇连贯、章节结构、伏笔回收或风格压力时',
        ),
      ],
      notes: const <String>[
        '章节阶段默认只读摘要；真正需要结构、对白、悬念或去 AI 细则时再细读对应 reference。',
      ],
    );
  }

  SkillRoutingPolicy _reviewPolicy(SkillActivationSignal signal) {
    final references = <String>{
      'references/graph-and-recall-control.md',
      'references/forgotten-elements-and-line-heat.md',
      'references/continuity-and-marathon-mode.md',
    };
    if (signal.hasFlag('authenticity_pass')) {
      references.add('references/authenticity-and-de-ai-pass.md');
    }
    return SkillRoutingPolicy(
      stageId: 'review',
      presets: <StageSkillPreset>[
        const StageSkillPreset(
          skillId: 'check_continuity',
          preloadDetailLevel: 'summary',
          reason: '审稿要先看问题分层和最小修复路径时',
        ),
        StageSkillPreset(
          skillId: 'novel-control-station',
          preloadDetailLevel: 'summary',
          referencePaths: references.toList(growable: false),
          reason: '需要更重的长篇回收、关系干涉或风格复核规则时',
        ),
      ],
      notes: const <String>[
        '审稿阶段先产出问题和修复建议，不要直接把 reference 里的方法全文灌回正文。',
      ],
    );
  }

  SkillRoutingPolicy _revisionPolicy(SkillActivationSignal signal) {
    final references = <String>{
      'references/chapter-architecture-rules.md',
      'references/scene-execution-patterns.md',
      'references/continuity-and-marathon-mode.md',
    };
    if (signal.hasFlag('authenticity_pass') || signal.hasFlag('continuity_pressure')) {
      references.add('references/authenticity-and-de-ai-pass.md');
    }
    return SkillRoutingPolicy(
      stageId: 'revision',
      presets: <StageSkillPreset>[
        const StageSkillPreset(
          skillId: 'check_continuity',
          preloadDetailLevel: 'summary',
          reason: '修订前先确认问题边界和最小改动面时',
        ),
        const StageSkillPreset(
          skillId: 'chapter_drafting_method',
          preloadDetailLevel: 'summary',
          reason: '需要把修订意见落实成更顺滑正文时',
        ),
        StageSkillPreset(
          skillId: 'novel-control-station',
          preloadDetailLevel: 'summary',
          referencePaths: references.toList(growable: false),
          reason: '需要章节结构修复、连续性补丁或去 AI 清理时',
        ),
      ],
      notes: const <String>[
        '修订阶段先用摘要校准动作，再按具体问题细读 reference，不要整份技能全文反复重载。',
      ],
    );
  }

  SkillRoutingPolicy _generalDraftPolicy(SkillActivationSignal signal) {
    final presets = <StageSkillPreset>[
      if (_containsAny(
        signal.userPrompt,
        const <String>['大纲', '总纲', '卷纲', '章纲', '规划'],
      ))
        const StageSkillPreset(
          skillId: 'generate_outline',
          preloadDetailLevel: 'summary',
          reason: '需要先搭结构时',
        )
      else
        const StageSkillPreset(
          skillId: 'chapter_drafting_method',
          preloadDetailLevel: 'summary',
          reason: '直接生成章节或场景正文时',
        ),
    ];
    return SkillRoutingPolicy(
      stageId: 'general_draft',
      presets: presets,
      notes: const <String>[
        '普通草稿阶段只预载最贴近当前任务的一个技能摘要，避免无关技能抢上下文预算。',
      ],
    );
  }

  String _resolveStageId(String intent, String taskType, String text) {
    if (taskType == 'planning' || _containsAny(text, const <String>['总纲', '卷纲', '章纲', '规划'])) {
      return 'planning';
    }
    if (taskType == 'review' || _containsAny(text, const <String>['审稿', '检查', '评估'])) {
      return 'review';
    }
    if (taskType == 'revision' || _containsAny(text, const <String>['修订', '返工', '重写'])) {
      return 'revision';
    }
    if (taskType == 'chapter' ||
        intent == 'workflow_task' ||
        _containsAny(text, const <String>['章节', '正文', '续写', '场景'])) {
      return 'chapter_drafting';
    }
    return 'general_draft';
  }

  bool _containsAny(String text, List<String> patterns) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }
    for (final pattern in patterns) {
      if (normalized.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
