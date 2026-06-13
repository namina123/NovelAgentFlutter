import 'repair_blocking_state.dart';
import 'repair_contract_catalog.dart';
import 'repair_outcome.dart';
import 'repair_request.dart';
import 'repair_task.dart';

class RepairLaneBlockingService {
  const RepairLaneBlockingService();

  RepairBlockingState blockingState({
    required RepairRequest request,
    RepairTask? task,
    RepairOutcome? outcome,
  }) {
    if (!request.blocksMainFlow) {
      return const RepairBlockingState(
        blocksMainFlow: false,
        reason: 'repair_request_non_blocking',
        resolved: true,
      );
    }
    if (outcome != null) {
      switch (outcome.status) {
        case RepairOutcomeStatuses.completed:
          return const RepairBlockingState(
            blocksMainFlow: false,
            reason: 'repair_completed',
            resolved: true,
          );
        case RepairOutcomeStatuses.noteOnly:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'blocking_repair_cannot_resolve_as_note_only',
            resolved: false,
          );
        case RepairOutcomeStatuses.waitingUser:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_waiting_user',
            waitingUser: true,
            resolved: false,
          );
        case RepairOutcomeStatuses.manualAttention:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_manual_attention',
            manualAttentionRequired: true,
            resolved: false,
          );
        case RepairOutcomeStatuses.failed:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_failed',
            resolved: false,
          );
        case RepairOutcomeStatuses.cancelled:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_cancelled_before_resolution',
            resolved: false,
          );
      }
    }
    if (task != null) {
      switch (task.status) {
        case RepairTaskStatuses.completed:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_completed_pending_outcome',
            resolved: false,
          );
        case RepairTaskStatuses.waitingUser:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_waiting_user',
            waitingUser: true,
            resolved: false,
          );
        case RepairTaskStatuses.failed:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_failed',
            resolved: false,
          );
        case RepairTaskStatuses.cancelled:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_cancelled',
            resolved: false,
          );
        case RepairTaskStatuses.inProgress:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_in_progress',
            resolved: false,
          );
        case RepairTaskStatuses.queued:
          return const RepairBlockingState(
            blocksMainFlow: true,
            reason: 'repair_task_queued',
            resolved: false,
          );
      }
    }
    return const RepairBlockingState(
      blocksMainFlow: true,
      reason: 'repair_request_pending_task',
      resolved: false,
    );
  }
}
