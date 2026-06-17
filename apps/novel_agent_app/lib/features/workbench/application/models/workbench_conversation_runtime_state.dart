import 'conversation_session_state.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'opening_session_projection.dart';

class WorkbenchConversationRuntimeState {
  const WorkbenchConversationRuntimeState({
    this.sessions = const <ConversationSessionState>[],
    this.activeSessionId = '',
    this.showSessionHistory = false,
    this.sessionRestoreResult,
    this.guideScope = '',
    this.activeModeGuidanceState,
    this.openingProjection,
    this.isOpeningProjectionRefreshing = false,
  });

  final List<ConversationSessionState> sessions;
  final String activeSessionId;
  final bool showSessionHistory;
  final SessionRestoreResult? sessionRestoreResult;
  final String guideScope;
  final ModeGuidanceState? activeModeGuidanceState;
  final OpeningSessionProjection? openingProjection;
  final bool isOpeningProjectionRefreshing;

  WorkbenchConversationRuntimeState copyWith({
    List<ConversationSessionState>? sessions,
    String? activeSessionId,
    bool? showSessionHistory,
    Object? sessionRestoreResult = _sessionRestoreResultSentinel,
    String? guideScope,
    Object? activeModeGuidanceState = _modeStateSentinel,
    Object? openingProjection = _openingProjectionSentinel,
    bool? isOpeningProjectionRefreshing,
  }) {
    // 中文注释: 会话运行时状态独立持有，保证项目工作区和会话链能各自演化。
    return WorkbenchConversationRuntimeState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      showSessionHistory: showSessionHistory ?? this.showSessionHistory,
      sessionRestoreResult:
          identical(sessionRestoreResult, _sessionRestoreResultSentinel)
          ? this.sessionRestoreResult
          : sessionRestoreResult as SessionRestoreResult?,
      guideScope: guideScope ?? this.guideScope,
      activeModeGuidanceState:
          identical(activeModeGuidanceState, _modeStateSentinel)
          ? this.activeModeGuidanceState
          : activeModeGuidanceState as ModeGuidanceState?,
      openingProjection:
          identical(openingProjection, _openingProjectionSentinel)
          ? this.openingProjection
          : openingProjection as OpeningSessionProjection?,
      isOpeningProjectionRefreshing:
          isOpeningProjectionRefreshing ?? this.isOpeningProjectionRefreshing,
    );
  }
}

const Object _modeStateSentinel = Object();
const Object _openingProjectionSentinel = Object();
const Object _sessionRestoreResultSentinel = Object();
