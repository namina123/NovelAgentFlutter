import 'domain_tool_request.dart';
import 'narrative_domain_tool_parse_issue.dart';

class NarrativeDomainToolParseResult {
  const NarrativeDomainToolParseResult({
    required this.toolName,
    this.request,
    this.issues = const <NarrativeDomainToolParseIssue>[],
  });

  final String toolName;
  final DomainToolRequest? request;
  final List<NarrativeDomainToolParseIssue> issues;

  bool get isSuccess => request != null && issues.isEmpty;
}
