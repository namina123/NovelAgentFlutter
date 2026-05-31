import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/conversation_agent_selector_view_data.dart';
import '../models/conversation_request_agent_resolution.dart';
import '../models/opening_agent_member_summary.dart';
import '../models/opening_primary_agent_summary.dart';
import '../models/opening_session_projection.dart';

class ConversationRequestAgentResolverService {
  const ConversationRequestAgentResolverService();

  ConversationRequestAgentResolution resolve({
    required OpeningSessionProjection? openingProjection,
    required String preferredAgentId,
    required ConversationAgentSelectorViewData fallbackSelector,
  }) {
    final projection = openingProjection;
    if (projection != null) {
      final selectedMember = _resolveSelectedMember(
        projection.availableAgentSummaries,
        preferredAgentId: preferredAgentId,
      );
      if (selectedMember != null) {
        return ConversationRequestAgentResolution(
          agentId: selectedMember.agentId,
          agent: _memberAgentDocument(selectedMember),
        );
      }
      final primarySummary = projection.currentPrimaryAgentSummary;
      if (primarySummary != null) {
        return ConversationRequestAgentResolution(
          agentId: primarySummary.agentId,
          agent: _primaryAgentDocument(primarySummary),
        );
      }
    }
    final fallbackAgentId = fallbackSelector.currentAgentId.trim();
    if (fallbackAgentId.isEmpty) {
      return const ConversationRequestAgentResolution(
        agentId: '',
        agent: <String, Object?>{},
      );
    }
    return ConversationRequestAgentResolution(
      agentId: fallbackAgentId,
      agent: <String, Object?>{
        'id': fallbackAgentId,
        'name': fallbackSelector.currentAgentLabel,
        'role': fallbackSelector.currentAgentDescription,
      },
    );
  }

  OpeningAgentMemberSummary? _resolveSelectedMember(
    List<OpeningAgentMemberSummary> members, {
    required String preferredAgentId,
  }) {
    final cleanPreferredAgentId = preferredAgentId.trim();
    if (cleanPreferredAgentId.isNotEmpty) {
      for (final member in members) {
        if (member.agentId == cleanPreferredAgentId) {
          return member;
        }
      }
    }
    for (final member in members) {
      if (member.isPrimary) {
        return member;
      }
    }
    return members.isEmpty ? null : members.first;
  }

  JsonMap _memberAgentDocument(OpeningAgentMemberSummary member) {
    return <String, Object?>{
      'id': member.agentId,
      'name': member.displayName,
      'role': member.role,
      'description': member.description,
      'thinking_supported': member.thinkingSupported,
    };
  }

  JsonMap _primaryAgentDocument(OpeningPrimaryAgentSummary primarySummary) {
    return <String, Object?>{
      'id': primarySummary.agentId,
      'name': primarySummary.displayName,
      'role': primarySummary.role,
      'thinking_supported': primarySummary.thinkingSupported,
    };
  }
}
