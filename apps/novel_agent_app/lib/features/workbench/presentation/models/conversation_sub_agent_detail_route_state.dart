import 'package:flutter/foundation.dart';

@immutable
class ConversationSubAgentDetailRouteState {
  const ConversationSubAgentDetailRouteState({
    required this.activeRunId,
  });

  const ConversationSubAgentDetailRouteState.idle() : activeRunId = null;

  final String? activeRunId;

  bool get isPresenting => activeRunId != null;

  ConversationSubAgentDetailRouteState copyWith({
    Object? activeRunId = _sentinel,
  }) {
    return ConversationSubAgentDetailRouteState(
      activeRunId: identical(activeRunId, _sentinel)
          ? this.activeRunId
          : activeRunId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationSubAgentDetailRouteState &&
            other.activeRunId == activeRunId;
  }

  @override
  int get hashCode => activeRunId.hashCode;
}

const Object _sentinel = Object();
