import '../models/opening_agent_member_summary.dart';
import '../models/opening_primary_agent_summary.dart';
import '../models/opening_session_projection.dart';
import '../../presentation/models/conversation_agent_selector_view_data.dart';
import '../../presentation/models/selector_option_view_data.dart';
import 'conversation_group_display_text_policy.dart';

class ConversationAgentSelectorViewDataService {
  const ConversationAgentSelectorViewDataService({
    ConversationGroupDisplayTextPolicy? displayTextPolicy,
  }) : _displayTextPolicy =
           displayTextPolicy ?? const ConversationGroupDisplayTextPolicy();

  final ConversationGroupDisplayTextPolicy _displayTextPolicy;

  ConversationAgentSelectorViewData build({
    required OpeningSessionProjection? openingProjection,
    required String preferredAgentId,
    required ConversationAgentSelectorViewData fallback,
  }) {
    final projection = openingProjection;
    if (projection == null) {
      return ConversationAgentSelectorViewData(
        currentAgentLabel: _displayTextPolicy.primaryAgentLabel(
          null,
          fallbackLabel: fallback.currentAgentLabel,
        ),
        currentAgentId: fallback.currentAgentId,
        currentAgentDescription: fallback.currentAgentDescription,
        agentOptions: const <SelectorOptionViewData>[],
        canSwitchAgent: false,
        headerSubtitle: fallback.headerSubtitle,
      );
    }
    final agentOptions = projection.availableAgentSummaries
        .map(_toSelectorOption)
        .toList(growable: false);
    final selectedMember = _resolveSelectedMember(
      projection.availableAgentSummaries,
      preferredAgentId: preferredAgentId,
    );
    final primarySummary = projection.currentPrimaryAgentSummary;
    return ConversationAgentSelectorViewData(
      currentAgentLabel: _currentAgentLabel(
        selectedMember,
        primarySummary: primarySummary,
        fallback: fallback,
      ),
      currentAgentId:
          selectedMember?.agentId ??
          primarySummary?.agentId ??
          fallback.currentAgentId,
      currentAgentDescription: _currentAgentDescription(
        selectedMember,
        primarySummary: primarySummary,
        fallback: fallback,
      ),
      agentOptions: agentOptions,
      canSwitchAgent: agentOptions.length > 1,
      headerSubtitle: _headerSubtitleOf(selectedMember),
    );
  }

  SelectorOptionViewData _toSelectorOption(OpeningAgentMemberSummary summary) {
    final noteParts = <String>[];
    final role = summary.role.trim();
    if (role.isNotEmpty) {
      noteParts.add(role);
    }
    final description = summary.description.trim();
    if (description.isNotEmpty) {
      noteParts.add(description);
    }
    return SelectorOptionViewData(
      id: summary.agentId,
      label: _displayTextPolicy.primaryAgentLabel(summary.displayName),
      note: noteParts.join(' · '),
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

  String _currentAgentLabel(
    OpeningAgentMemberSummary? selectedMember, {
    required OpeningPrimaryAgentSummary? primarySummary,
    required ConversationAgentSelectorViewData fallback,
  }) {
    return _displayTextPolicy.primaryAgentLabel(
      selectedMember?.displayName,
      fallbackLabel: selectedMember == null
          ? (primarySummary?.displayName.trim().isNotEmpty ?? false)
                ? primarySummary!.displayName
                : fallback.currentAgentLabel
          : fallback.currentAgentLabel,
    );
  }

  String _currentAgentDescription(
    OpeningAgentMemberSummary? selectedMember, {
    required OpeningPrimaryAgentSummary? primarySummary,
    required ConversationAgentSelectorViewData fallback,
  }) {
    final role = selectedMember?.role.trim() ?? '';
    if (role.isNotEmpty) {
      return role;
    }
    final description = selectedMember?.description.trim() ?? '';
    if (description.isNotEmpty) {
      return description;
    }
    final primaryRole = primarySummary?.role.trim() ?? '';
    if (primaryRole.isNotEmpty) {
      return primaryRole;
    }
    return fallback.currentAgentDescription;
  }

  String? _headerSubtitleOf(OpeningAgentMemberSummary? selectedMember) {
    final role = selectedMember?.role.trim() ?? '';
    return role.isEmpty ? null : role;
  }
}
