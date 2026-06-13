import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_tool_exposure_profile.dart';

class ContinuousTaskToolExposureRuntimeResolution {
  const ContinuousTaskToolExposureRuntimeResolution({
    required this.taskProfile,
    required this.exposureProfile,
    this.groupSupportedCapabilityFamilyIds = const <String>[],
    this.defaultOpenCapabilityFamilyIds = const <String>[],
    this.requiresConfirmationCapabilityFamilyIds = const <String>[],
    this.hostOrSupervisorOnlyCapabilityFamilyIds = const <String>[],
    this.defaultAllowedToolIds = const <String>[],
    this.requiresConfirmationToolIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final ContinuousTaskProfile taskProfile;
  final ContinuousTaskToolExposureProfile exposureProfile;
  final List<String> groupSupportedCapabilityFamilyIds;
  final List<String> defaultOpenCapabilityFamilyIds;
  final List<String> requiresConfirmationCapabilityFamilyIds;
  final List<String> hostOrSupervisorOnlyCapabilityFamilyIds;
  final List<String> defaultAllowedToolIds;
  final List<String> requiresConfirmationToolIds;
  final JsonMap metadata;

  List<String> get visibleToolIds {
    final result = <String>[];
    for (final toolId in <String>[
      ...defaultAllowedToolIds,
      ...requiresConfirmationToolIds,
    ]) {
      final cleanToolId = toolId.trim();
      if (cleanToolId.isEmpty || result.contains(cleanToolId)) {
        continue;
      }
      result.add(cleanToolId);
    }
    return List<String>.unmodifiable(result);
  }

  JsonMap toJson() {
    return <String, Object?>{
      'task_profile': taskProfile.toJson(),
      'exposure_profile': exposureProfile.toJson(),
      'group_supported_capability_family_ids': List<String>.from(
        groupSupportedCapabilityFamilyIds,
      ),
      'default_open_capability_family_ids': List<String>.from(
        defaultOpenCapabilityFamilyIds,
      ),
      'requires_confirmation_capability_family_ids': List<String>.from(
        requiresConfirmationCapabilityFamilyIds,
      ),
      'host_or_supervisor_only_capability_family_ids': List<String>.from(
        hostOrSupervisorOnlyCapabilityFamilyIds,
      ),
      'default_allowed_tool_ids': List<String>.from(defaultAllowedToolIds),
      'requires_confirmation_tool_ids': List<String>.from(
        requiresConfirmationToolIds,
      ),
      'visible_tool_ids': List<String>.from(visibleToolIds),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
