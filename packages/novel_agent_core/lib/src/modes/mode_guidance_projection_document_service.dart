import 'mode_guidance_state.dart';

class ModeGuidanceProjectionDocumentService {
  const ModeGuidanceProjectionDocumentService();

  Map<String, String> buildDocuments(ModeGuidanceState state) {
    // 中文注释: 该服务把模式状态投影成用户可见 Markdown 资产，避免只有隐藏状态和摘要却没有正式项目材料。
    switch (state.modeId) {
      case 'seed_autopilot_novel':
        return _seedAutopilotDocuments(state);
      case 'full_outline_consensus':
        return _fullOutlineConsensusDocuments(state);
      default:
        return const <String, String>{};
    }
  }

  Map<String, String> _seedAutopilotDocuments(ModeGuidanceState state) {
    final values = <String, String>{};
    for (final answer in state.answers) {
      values[answer.fieldKey] = answer.value.trim();
    }
    final seedScope = values['seed_scope'] ?? '';
    final corePromise = values['core_promise'] ?? '';
    final worldAnchor = values['world_anchor'] ?? '';
    final protagonistDrive = values['protagonist_drive'] ?? '';
    final styleTarget = values['style_target'] ?? '';
    final autonomyGuardrails = values['autonomy_guardrails'] ?? '';
    return <String, String>{
      'inspiration/seed_autopilot_seed.md':
          '''
# 长任务创作种子

- 当前材料：$seedScope
- 核心承诺：$corePromise
- 托管状态：${state.isReady ? '已具备启动条件' : '仍在收集'}

## 当前说明

这份文档是第一种长任务模式的种子投影。  
它代表当前已经确认的创作方向，但不等于总纲定稿。
''',
      'specs/seed_autopilot_constraints.md':
          '''
# 长任务托管约束

- 核心承诺：$corePromise
- 托管边界：$autonomyGuardrails

## 生成要求

1. 先纲后文
2. 先确认长期约束，再扩张章节计划
3. 不要把未确认脑洞当作既定事实
''',
      'world/seed_autopilot_world_anchor.md':
          '''
# 世界锚点

$worldAnchor

## 作用

这份文档描述长期规划不可随意违背的世界边界。  
后续总纲、卷纲、章纲与正文都应优先服从这里。
''',
      'characters/seed_autopilot_protagonist.md':
          '''
# 主角驱动力

$protagonistDrive

## 作用

这份文档只定义主角长期驱动力，不代表完整角色卡。  
后续如需扩写角色履历、关系与阶段状态，应在此基础上继续补全。
''',
      'styles/seed_autopilot_style.md':
          '''
# 风格目标

$styleTarget

## 写作要求

- 保持风格连续
- 避免与这里明显冲突的表达方式
- 若后续需要风格修订，应新增风格补充而不是直接遗忘此文档
''',
    };
  }

  Map<String, String> _fullOutlineConsensusDocuments(ModeGuidanceState state) {
    final values = <String, String>{};
    for (final answer in state.answers) {
      values[answer.fieldKey] = answer.value.trim();
    }
    final premise = values['book_premise'] ?? '';
    final mainArc = values['main_arc'] ?? '';
    final volumeMap = values['volume_map'] ?? '';
    final ending = values['ending_commitment'] ?? '';
    final style = values['style_and_boundaries'] ?? '';
    return <String, String>{
      'outline/full_outline_consensus_overview.md':
          '''
# 全书共识总览

- 故事总前提：$premise
- 主线与冲突：$mainArc
- 结局承诺：$ending

## 说明

这份文档代表全书共拟模式当前已经确认的主线共识。  
后续正式总纲、卷纲和章纲都应从这里展开，而不是重新发散。
''',
      'characters/full_outline_consensus_core_roles.md':
          '''
# 核心角色关注点

## 主角侧

$premise

## 主线冲突侧

$mainArc

## 说明

这里先记录核心角色与冲突焦点。  
即使完整角色卡还未展开，后续总纲与卷纲也应围绕这些焦点推进。
''',
      'volume_outlines/full_outline_consensus_volumes.md':
          '''
# 分卷共识

$volumeMap

## 说明

这里记录的是当前已经讨论过的分卷结构。  
如果后续需要调整分卷节奏，应先更新这里，再让长任务执行层跟进。
''',
      'specs/full_outline_consensus_constraints.md':
          '''
# 全书共拟约束

- 结局承诺：$ending
- 风格与边界：$style

## 生成要求

1. 先完成总纲与卷纲
2. 主线和结局方向不得在未确认的情况下漂移
3. 重大结构变更前需要回到用户确认
''',
      'styles/full_outline_consensus_style.md':
          '''
# 全书共拟风格

$style

## 说明

这份文档描述全书层面的统一风格要求。  
后续章节写作与修订都应参考这里。
''',
    };
  }
}
