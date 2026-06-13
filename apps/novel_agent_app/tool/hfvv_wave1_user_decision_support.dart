import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';

class HfvvLaneAUserDecision {
  const HfvvLaneAUserDecision._({
    required this.strategy,
    required this.option,
    required this.followUpPrompt,
    required this.reason,
  });

  const HfvvLaneAUserDecision.selectOption({
    required UserOptionViewData option,
    required String reason,
  }) : this._(
         strategy: 'select_pending_option',
         option: option,
         followUpPrompt: '',
         reason: reason,
       );

  const HfvvLaneAUserDecision.sendFollowUp({
    required String followUpPrompt,
    required String reason,
  }) : this._(
         strategy: 'send_follow_up_prompt',
         option: null,
         followUpPrompt: followUpPrompt,
         reason: reason,
       );

  final String strategy;
  final UserOptionViewData? option;
  final String followUpPrompt;
  final String reason;
}

HfvvLaneAUserDecision decideLaneAResearchFirstStep(
  List<UserOptionViewData> options,
) {
  for (final option in options) {
    final text = _optionText(option);
    if (_containsAny(text, _laneAResearchFirstDisqualifiers)) {
      continue;
    }
    if (_containsAny(text, _laneAExplicitResearchFirstSignals)) {
      return HfvvLaneAUserDecision.selectOption(
        option: option,
        reason: 'matched_explicit_research_first_option',
      );
    }
  }
  return const HfvvLaneAUserDecision.sendFollowUp(
    followUpPrompt: _laneAResearchFirstFollowUpPrompt,
    reason: 'no_explicit_research_first_option',
  );
}

String _optionText(UserOptionViewData option) {
  return '${option.label} ${option.description} ${option.prompt}';
}

bool _containsAny(String text, List<String> fragments) {
  for (final fragment in fragments) {
    if (text.contains(fragment)) {
      return true;
    }
  }
  return false;
}

const List<String> _laneAExplicitResearchFirstSignals = <String>[
  '资料先行',
  '信息先行',
  '资料优先',
  '研究优先',
  '先做资料',
  '先查资料',
  '先整理资料',
  '先补资料',
  '先做研究',
  '先研究',
  '先核查',
  '先考据',
  '先做考据',
  '先做资料整理',
  '先做背景研究',
];

const List<String> _laneAResearchFirstDisqualifiers = <String>[
  '资料为辅',
  '边走边查',
  '先定主角',
  '先定开局',
  '先给开局',
  '先写',
  '先出一章',
  '直接写',
  '正文优先',
  '试写优先',
  '先定框架',
];

const String _laneAResearchFirstFollowUpPrompt = '''
我选择信息先行路线。

这一步先不要写章节正文，也不要先定主角开局。请先基于当前项目做两件事：
1. 列出这个题材里哪些内容必须先核查资料，并按高/中/低风险分级。
2. 能整理的先整理成研究记录、知识条目或资料卡；如果需要联网或继续考据，请明确发起资料研究。

在完成这一步之前，不要交付 chapter 文件。
''';

const String laneAResearchMaterializationFollowUpPrompt = '''
我接受这个资料严谨度分级。

现在请继续把高风险和中风险项整理成可回看的资料缺口清单，并尽量落成研究记录、知识条目或 premise 补充；如果需要联网或继续考据，请明确发起资料研究。

除非缺少最少必要确认，否则不要停在新的选项上；这一轮也不要写正文。
''';

bool shouldRequestLaneBActualSubAgents({
  required List<SubAgentRunViewData> subAgentRuns,
  required String latestAssistant,
}) {
  if (subAgentRuns.isNotEmpty) {
    return false;
  }
  return latestAssistant.trim().isNotEmpty;
}

const String laneBActualSubAgentFollowUpPrompt = '''
上一轮没有看到真实的子智能体运行轨迹。

请不要只用“视角一 / 视角二 / 视角三”口头模拟协作；请实际调用资料考据、角色设定、剧情审核等子智能体，让它们各自产生可见运行记录，然后再由主智能体综合输出结果。
''';
