import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_state.dart';
import 'opening_intent_snapshot.dart';
import 'opening_stage_record.dart';

class OpeningSessionState {
  const OpeningSessionState({
    required this.projectTypeId,
    required this.status,
    required this.intent,
    required this.stageRecords,
    required this.createdAt,
    required this.updatedAt,
    this.modeGuidanceState,
    this.metadata = const <String, Object?>{},
  });

  static const String statusCollecting = 'collecting';
  static const String statusReadyForLongTask = 'ready_for_long_task';
  static const String statusReadyForInteractiveSession =
      'ready_for_interactive_session';

  final String projectTypeId;
  final String status;
  final OpeningIntentSnapshot intent;
  final List<OpeningStageRecord> stageRecords;
  final String createdAt;
  final String updatedAt;
  final ModeGuidanceState? modeGuidanceState;
  final JsonMap metadata;

  OpeningSessionState copyWith({
    String? projectTypeId,
    String? status,
    OpeningIntentSnapshot? intent,
    List<OpeningStageRecord>? stageRecords,
    String? createdAt,
    String? updatedAt,
    Object? modeGuidanceState = _modeGuidanceSentinel,
    JsonMap? metadata,
  }) {
    // 中文注释: opening 状态作为总快照对象流转，后续 app 与仓储都只消费这个不可变结果。
    return OpeningSessionState(
      projectTypeId: projectTypeId ?? this.projectTypeId,
      status: status ?? this.status,
      intent: intent ?? this.intent,
      stageRecords: stageRecords ?? this.stageRecords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modeGuidanceState: identical(modeGuidanceState, _modeGuidanceSentinel)
          ? this.modeGuidanceState
          : modeGuidanceState as ModeGuidanceState?,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJsonMap() {
    return <String, Object?>{
      'project_type_id': projectTypeId,
      'status': status,
      'intent': intent.toJsonMap(),
      'stage_records': stageRecords
          .map((record) => record.toJsonMap())
          .cast<Object?>()
          .toList(growable: false),
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (modeGuidanceState != null)
        'mode_guidance_state': modeGuidanceState!.toJsonMap(),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static OpeningSessionState fromJsonMap(JsonMap document) {
    return OpeningSessionState(
      projectTypeId: ValueReaders.stringValue(
        document['project_type_id'],
      ).trim(),
      status: ValueReaders.stringValue(document['status'], statusCollecting),
      intent: OpeningIntentSnapshot.fromJsonMap(
        ValueReaders.mapValue(document['intent']),
      ),
      stageRecords: ValueReaders.mapList(
        document['stage_records'],
      ).map(OpeningStageRecord.fromJsonMap).toList(growable: false),
      createdAt: ValueReaders.stringValue(document['created_at']).trim(),
      updatedAt: ValueReaders.stringValue(document['updated_at']).trim(),
      modeGuidanceState:
          ValueReaders.mapValue(document['mode_guidance_state']).isEmpty
          ? null
          : ModeGuidanceState.fromJsonMap(
              ValueReaders.mapValue(document['mode_guidance_state']),
            ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
    );
  }
}

const Object _modeGuidanceSentinel = Object();
