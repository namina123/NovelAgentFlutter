import '../common/json_types.dart';

class ModeGuidancePlanInput {
  const ModeGuidancePlanInput({
    required this.modeId,
    required this.runtimeMode,
    required this.isReady,
    required this.options,
    this.missingFields = const <String>[],
  });

  final String modeId;
  final String runtimeMode;
  final bool isReady;
  final JsonMap options;
  final List<String> missingFields;
}
