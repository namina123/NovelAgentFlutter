import 'package:flutter/foundation.dart';

import 'selector_option_view_data.dart';

@immutable
class ConversationAgentSelectorViewData {
  const ConversationAgentSelectorViewData({
    required this.currentAgentLabel,
    required this.currentAgentId,
    required this.currentAgentDescription,
    required this.agentOptions,
    required this.canSwitchAgent,
    this.headerSubtitle,
  });

  const ConversationAgentSelectorViewData.initial()
    : currentAgentLabel = '综合创作智能体',
      currentAgentId = '',
      currentAgentDescription = '',
      agentOptions = const <SelectorOptionViewData>[],
      canSwitchAgent = false,
      headerSubtitle = null;

  final String currentAgentLabel;
  final String currentAgentId;
  final String currentAgentDescription;
  final List<SelectorOptionViewData> agentOptions;
  final bool canSwitchAgent;
  final String? headerSubtitle;

  ConversationAgentSelectorViewData copyWith({
    String? currentAgentLabel,
    String? currentAgentId,
    String? currentAgentDescription,
    List<SelectorOptionViewData>? agentOptions,
    bool? canSwitchAgent,
    Object? headerSubtitle = _headerSubtitleSentinel,
  }) {
    return ConversationAgentSelectorViewData(
      currentAgentLabel: currentAgentLabel ?? this.currentAgentLabel,
      currentAgentId: currentAgentId ?? this.currentAgentId,
      currentAgentDescription:
          currentAgentDescription ?? this.currentAgentDescription,
      agentOptions: agentOptions ?? this.agentOptions,
      canSwitchAgent: canSwitchAgent ?? this.canSwitchAgent,
      headerSubtitle: identical(headerSubtitle, _headerSubtitleSentinel)
          ? this.headerSubtitle
          : headerSubtitle as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationAgentSelectorViewData &&
            other.currentAgentLabel == currentAgentLabel &&
            other.currentAgentId == currentAgentId &&
            other.currentAgentDescription == currentAgentDescription &&
            listEquals(other.agentOptions, agentOptions) &&
            other.canSwitchAgent == canSwitchAgent &&
            other.headerSubtitle == headerSubtitle;
  }

  @override
  int get hashCode => Object.hash(
    currentAgentLabel,
    currentAgentId,
    currentAgentDescription,
    Object.hashAll(agentOptions),
    canSwitchAgent,
    headerSubtitle,
  );
}

const Object _headerSubtitleSentinel = Object();
