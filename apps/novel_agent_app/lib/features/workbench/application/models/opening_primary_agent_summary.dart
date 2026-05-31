class OpeningPrimaryAgentSummary {
  const OpeningPrimaryAgentSummary({
    required this.agentId,
    required this.displayName,
    required this.role,
    required this.thinkingSupported,
  });

  final String agentId;
  final String displayName;
  final String role;
  final bool thinkingSupported;
}
