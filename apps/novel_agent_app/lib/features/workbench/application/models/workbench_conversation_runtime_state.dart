import 'conversation_session_state.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class WorkbenchConversationRuntimeState {
  const WorkbenchConversationRuntimeState({
    this.sessions = const <ConversationSessionState>[],
    this.activeSessionId = '',
    this.showSessionHistory = false,
    this.guideScope = '',
    this.activeModeGuidanceState,
  });

  final List<ConversationSessionState> sessions;
  final String activeSessionId;
  final bool showSessionHistory;
  final String guideScope;
  final ModeGuidanceState? activeModeGuidanceState;

  WorkbenchConversationRuntimeState copyWith({
    List<ConversationSessionState>? sessions,
    String? activeSessionId,
    bool? showSessionHistory,
    String? guideScope,
    Object? activeModeGuidanceState = _modeStateSentinel,
  }) {
    // 中文注释: 会话运行时状态独立持有，保证项目工作区和会话链能各自演化。
    return WorkbenchConversationRuntimeState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      showSessionHistory: showSessionHistory ?? this.showSessionHistory,
      guideScope: guideScope ?? this.guideScope,
      activeModeGuidanceState:
          identical(activeModeGuidanceState, _modeStateSentinel)
          ? this.activeModeGuidanceState
          : activeModeGuidanceState as ModeGuidanceState?,
    );
  }
}

const Object _modeStateSentinel = Object();
