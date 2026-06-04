import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'domain_tool_error.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';

class DomainToolCodecService {
  const DomainToolCodecService();

  DomainToolRequest requestFromJson(JsonMap json) {
    return DomainToolRequest.fromJson(json);
  }

  JsonMap requestToJson(DomainToolRequest request) {
    return request.toJson();
  }

  DomainToolPermissionDecision permissionDecisionFromJson(JsonMap json) {
    return DomainToolPermissionDecision.fromJson(json);
  }

  JsonMap permissionDecisionToJson(DomainToolPermissionDecision decision) {
    return decision.toJson();
  }

  DomainToolError errorFromJson(JsonMap json) {
    return DomainToolError.fromJson(json);
  }

  JsonMap errorToJson(DomainToolError error) {
    return error.toJson();
  }

  DomainToolOutcome outcomeFromJson(JsonMap json) {
    return DomainToolOutcome.fromJson(json);
  }

  JsonMap outcomeToJson(DomainToolOutcome outcome) {
    return outcome.toJson();
  }

  List<DomainToolOutcome> outcomesFromJsonList(Object? rawOutcomes) {
    return ValueReaders.mapList(
      rawOutcomes,
    ).map(DomainToolOutcome.fromJson).toList(growable: false);
  }
}
