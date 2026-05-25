import 'package:novel_agent_core/novel_agent_core.dart';

import 'conversation_retry_request.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/sub_agent_run_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';

class ConversationSessionState {
  const ConversationSessionState({
    required this.sessionRecord,
    required this.entries,
    required this.pendingOptions,
    required this.subAgentRuns,
    required this.retryRequest,
  });

  final JsonMap sessionRecord;
  final List<ConversationEntryViewData> entries;
  final List<UserOptionViewData> pendingOptions;
  final List<SubAgentRunViewData> subAgentRuns;
  final ConversationRetryRequest? retryRequest;

  ConversationSessionState copyWith({
    JsonMap? sessionRecord,
    List<ConversationEntryViewData>? entries,
    List<UserOptionViewData>? pendingOptions,
    List<SubAgentRunViewData>? subAgentRuns,
    Object? retryRequest = _retryRequestSentinel,
  }) {
    // 中文注释: 会话状态使用不可变快照，方便控制器在切换历史和回放时保持一致性。
    return ConversationSessionState(
      sessionRecord: sessionRecord ?? this.sessionRecord,
      entries: entries ?? this.entries,
      pendingOptions: pendingOptions ?? this.pendingOptions,
      subAgentRuns: subAgentRuns ?? this.subAgentRuns,
      retryRequest: identical(retryRequest, _retryRequestSentinel)
          ? this.retryRequest
          : retryRequest as ConversationRetryRequest?,
    );
  }
}

const Object _retryRequestSentinel = Object();
