import '../models/opening_agent_group_summary.dart';
import '../models/opening_primary_agent_summary.dart';
import '../models/opening_session_projection.dart';
import '../../presentation/models/conversation_group_selector_view_data.dart';
import '../../presentation/models/selector_option_view_data.dart';
import 'conversation_group_display_text_policy.dart';

class ConversationGroupSelectorViewDataService {
  const ConversationGroupSelectorViewDataService({
    ConversationGroupDisplayTextPolicy? displayTextPolicy,
  }) : _displayTextPolicy =
           displayTextPolicy ?? const ConversationGroupDisplayTextPolicy();

  final ConversationGroupDisplayTextPolicy _displayTextPolicy;

  ConversationGroupSelectorViewData build({
    required OpeningSessionProjection? openingProjection,
    required String fallbackPrimaryAgentLabel,
  }) {
    // 中文注释: 这里把 opening projection 收束成会话栏可直接消费的 group-first 选择合同，避免 UI 自己理解开局状态。
    final projection = openingProjection;
    final primarySummary = projection?.currentPrimaryAgentSummary;
    final groupOptions =
        projection?.supportedGroups
            .map(_toSelectorOption)
            .toList(growable: false) ??
        const <SelectorOptionViewData>[];
    return ConversationGroupSelectorViewData(
      currentGroupLabel: _displayTextPolicy.currentGroupLabel(
        projection?.currentGroupDisplayName,
      ),
      headerSubtitle: _displayTextPolicy.headerSubtitle(
        projection?.currentGroupDisplayName,
      ),
      groupOptions: groupOptions,
      primaryAgentLabel: _primaryAgentLabel(
        primarySummary,
        fallbackPrimaryAgentLabel: fallbackPrimaryAgentLabel,
      ),
      primaryAgentDescription: _primaryAgentDescription(primarySummary),
      canSwitchGroup: groupOptions.isNotEmpty,
    );
  }

  SelectorOptionViewData _toSelectorOption(OpeningAgentGroupSummary summary) {
    // 中文注释: 组选择器选项只保留当前会话真正需要的显示信息，不把 opening 面板的完整状态塞进下拉项。
    final noteParts = <String>[];
    if (summary.isDegraded == true) {
      noteParts.add('降级可用');
    }
    final description = summary.description.toString().trim();
    if (description.isNotEmpty) {
      noteParts.add(description);
    }
    return SelectorOptionViewData(
      id: summary.groupId.toString(),
      label: summary.displayName.toString(),
      note: noteParts.join(' · '),
    );
  }

  String _primaryAgentLabel(
    OpeningPrimaryAgentSummary? summary, {
    required String fallbackPrimaryAgentLabel,
  }) {
    // 中文注释: 主智能体显示名优先使用组解析结果；只有 projection 未就绪时才回退到设置层标签。
    return _displayTextPolicy.primaryAgentLabel(
      summary?.displayName,
      fallbackLabel: fallbackPrimaryAgentLabel,
    );
  }

  String _primaryAgentDescription(OpeningPrimaryAgentSummary? summary) {
    // 中文注释: 主智能体补充说明只暴露角色摘要，不再把内部 agent id 当成用户文案。
    return _displayTextPolicy.primaryAgentDescription(summary?.role);
  }
}
