import '../models/conversation_sub_agent_detail_route_state.dart';
import '../models/sub_agent_run_view_data.dart';

class ConversationSubAgentDetailRouteService {
  const ConversationSubAgentDetailRouteService();

  ConversationSubAgentDetailRouteState selectRun(
    ConversationSubAgentDetailRouteState current,
    SubAgentRunViewData run,
  ) {
    return current.copyWith(activeRunId: run.id);
  }

  ConversationSubAgentDetailRouteState clear(
    ConversationSubAgentDetailRouteState current,
  ) {
    if (!current.isPresenting) {
      return current;
    }
    return current.copyWith(activeRunId: null);
  }

  ConversationSubAgentDetailRouteState sanitize(
    ConversationSubAgentDetailRouteState current,
    List<SubAgentRunViewData> runs,
  ) {
    final activeRunId = current.activeRunId;
    if (activeRunId == null) {
      return current;
    }
    for (final run in runs) {
      if (run.id == activeRunId) {
        return current;
      }
    }
    return const ConversationSubAgentDetailRouteState.idle();
  }

  SubAgentRunViewData? resolveActiveRun(
    ConversationSubAgentDetailRouteState current,
    List<SubAgentRunViewData> runs,
  ) {
    final activeRunId = current.activeRunId;
    if (activeRunId == null) {
      return null;
    }
    for (final run in runs) {
      if (run.id == activeRunId) {
        return run;
      }
    }
    return null;
  }
}
