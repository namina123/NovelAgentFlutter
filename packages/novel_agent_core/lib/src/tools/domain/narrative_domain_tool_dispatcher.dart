import 'domain_tool_contract_typedefs.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_capability.dart';

abstract interface class NarrativeDomainToolDispatcher {
  List<NarrativeDomainToolCapability> get capabilities;

  NarrativeDomainToolCapability? capabilityFor(DomainToolName toolName);

  bool canDispatch(DomainToolName toolName);

  Future<DomainToolOutcome> dispatch({required DomainToolRequest request});
}
