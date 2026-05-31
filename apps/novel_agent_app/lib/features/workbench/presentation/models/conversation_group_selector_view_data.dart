import 'package:flutter/foundation.dart';

import 'selector_option_view_data.dart';

@immutable
class ConversationGroupSelectorViewData {
  const ConversationGroupSelectorViewData({
    required this.currentGroupLabel,
    this.headerSubtitle,
    required this.groupOptions,
    required this.primaryAgentLabel,
    required this.primaryAgentDescription,
    required this.canSwitchGroup,
  });

  const ConversationGroupSelectorViewData.initial()
    : currentGroupLabel = '未确定智能体组',
      headerSubtitle = null,
      groupOptions = const <SelectorOptionViewData>[],
      primaryAgentLabel = '综合创作智能体',
      primaryAgentDescription = '',
      canSwitchGroup = false;

  final String currentGroupLabel;
  final String? headerSubtitle;
  final List<SelectorOptionViewData> groupOptions;
  final String primaryAgentLabel;
  final String primaryAgentDescription;
  final bool canSwitchGroup;

  ConversationGroupSelectorViewData copyWith({
    String? currentGroupLabel,
    Object? headerSubtitle = _headerSubtitleSentinel,
    List<SelectorOptionViewData>? groupOptions,
    String? primaryAgentLabel,
    String? primaryAgentDescription,
    bool? canSwitchGroup,
  }) {
    // 中文注释: 组选择视图是独立投影对象，因此单独提供 copyWith 给工作台状态做小步更新。
    return ConversationGroupSelectorViewData(
      currentGroupLabel: currentGroupLabel ?? this.currentGroupLabel,
      headerSubtitle: identical(headerSubtitle, _headerSubtitleSentinel)
          ? this.headerSubtitle
          : headerSubtitle as String?,
      groupOptions: groupOptions ?? this.groupOptions,
      primaryAgentLabel: primaryAgentLabel ?? this.primaryAgentLabel,
      primaryAgentDescription:
          primaryAgentDescription ?? this.primaryAgentDescription,
      canSwitchGroup: canSwitchGroup ?? this.canSwitchGroup,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationGroupSelectorViewData &&
            other.currentGroupLabel == currentGroupLabel &&
            other.headerSubtitle == headerSubtitle &&
            listEquals(other.groupOptions, groupOptions) &&
            other.primaryAgentLabel == primaryAgentLabel &&
            other.primaryAgentDescription == primaryAgentDescription &&
            other.canSwitchGroup == canSwitchGroup;
  }

  @override
  int get hashCode => Object.hash(
    currentGroupLabel,
    headerSubtitle,
    Object.hashAll(groupOptions),
    primaryAgentLabel,
    primaryAgentDescription,
    canSwitchGroup,
  );
}

const Object _headerSubtitleSentinel = Object();
