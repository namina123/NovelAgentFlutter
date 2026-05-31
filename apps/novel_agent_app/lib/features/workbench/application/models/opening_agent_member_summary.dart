import 'package:flutter/foundation.dart';

@immutable
class OpeningAgentMemberSummary {
  const OpeningAgentMemberSummary({
    required this.agentId,
    required this.displayName,
    required this.role,
    required this.isPrimary,
    required this.thinkingSupported,
    this.description = '',
  });

  final String agentId;
  final String displayName;
  final String role;
  final bool isPrimary;
  final bool thinkingSupported;
  final String description;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpeningAgentMemberSummary &&
            other.agentId == agentId &&
            other.displayName == displayName &&
            other.role == role &&
            other.isPrimary == isPrimary &&
            other.thinkingSupported == thinkingSupported &&
            other.description == description;
  }

  @override
  int get hashCode => Object.hash(
    agentId,
    displayName,
    role,
    isPrimary,
    thinkingSupported,
    description,
  );
}
