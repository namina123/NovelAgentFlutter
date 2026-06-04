import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_capability.dart';

abstract interface class NarrativeDomainToolHandler {
  NarrativeDomainToolCapability get capability;

  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  });
}
