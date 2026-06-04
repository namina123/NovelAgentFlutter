import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'context_activation_item.dart';
import 'context_activation_plan.dart';
import 'context_activation_report.dart';

class ContextActivationCodecService {
  const ContextActivationCodecService();

  ContextActivationItem itemFromJson(JsonMap json) {
    return ContextActivationItem.fromJson(json);
  }

  JsonMap itemToJson(ContextActivationItem item) {
    return item.toJson();
  }

  ContextActivationPlan planFromJson(JsonMap json) {
    return ContextActivationPlan.fromJson(json);
  }

  JsonMap planToJson(ContextActivationPlan plan) {
    return plan.toJson();
  }

  ContextActivationReport reportFromJson(JsonMap json) {
    return ContextActivationReport.fromJson(json);
  }

  JsonMap reportToJson(ContextActivationReport report) {
    return report.toJson();
  }

  List<ContextActivationItem> itemsFromJsonList(Object? rawItems) {
    return ValueReaders.mapList(
      rawItems,
    ).map(ContextActivationItem.fromJson).toList(growable: false);
  }
}
