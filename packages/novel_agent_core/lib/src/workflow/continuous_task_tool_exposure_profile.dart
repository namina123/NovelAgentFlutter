import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/tool_capability_exposure_policy.dart';
import '../tools/tool_exposure_level.dart';

class ContinuousTaskToolExposureProfile {
  const ContinuousTaskToolExposureProfile({
    required this.profileId,
    required this.taskFamilyId,
    required this.runKind,
    this.capabilityPolicies = const <ToolCapabilityExposurePolicy>[],
    this.metadata = const <String, Object?>{},
  });

  final String profileId;
  final String taskFamilyId;
  final String runKind;
  final List<ToolCapabilityExposurePolicy> capabilityPolicies;
  final JsonMap metadata;

  List<String> capabilityFamilyIdsFor(String exposureLevel) {
    return capabilityPolicies
        .where((policy) => policy.exposureLevel == exposureLevel.trim())
        .map((policy) => policy.familyId)
        .toList(growable: false);
  }

  List<String> get defaultOpenFamilyIds {
    return capabilityFamilyIdsFor(ToolExposureLevels.defaultOpen);
  }

  List<String> get requiresConfirmationFamilyIds {
    return capabilityFamilyIdsFor(ToolExposureLevels.requiresConfirmation);
  }

  List<String> get hostOrSupervisorOnlyFamilyIds {
    return capabilityFamilyIdsFor(ToolExposureLevels.hostOrSupervisorOnly);
  }

  JsonMap toJson() {
    return <String, Object?>{
      'profile_id': profileId,
      'task_family_id': taskFamilyId,
      'run_kind': runKind,
      'capability_policies': capabilityPolicies
          .map((policy) => policy.toJson())
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ContinuousTaskToolExposureProfile fromJson(JsonMap json) {
    // 中文注释: 任务画像到工具暴露画像的绑定需要可序列化，方便后续 runtime/GUI/CLI 只消费同一生产合同。
    return ContinuousTaskToolExposureProfile(
      profileId: ValueReaders.stringValue(json['profile_id']).trim(),
      taskFamilyId: ValueReaders.stringValue(json['task_family_id']).trim(),
      runKind: ValueReaders.stringValue(json['run_kind']).trim(),
      capabilityPolicies: ValueReaders.objectList(json['capability_policies'])
          .map((rawPolicy) {
            return ToolCapabilityExposurePolicy.fromJson(
              ValueReaders.mapValue(rawPolicy),
            );
          })
          .toList(growable: false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (profileId.trim().isEmpty) {
      result.add('missing_continuous_task_tool_exposure_profile_id');
    }
    if (taskFamilyId.trim().isEmpty) {
      result.add('missing_continuous_task_tool_exposure_task_family_id');
    }
    if (runKind.trim().isEmpty) {
      result.add('missing_continuous_task_tool_exposure_run_kind');
    }
    for (final policy in capabilityPolicies) {
      result.addAll(policy.validateBasics());
    }
    return result;
  }
}
