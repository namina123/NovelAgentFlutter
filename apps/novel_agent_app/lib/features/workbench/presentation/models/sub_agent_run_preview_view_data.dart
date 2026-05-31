import 'package:flutter/foundation.dart';

@immutable
class SubAgentRunPreviewViewData {
  const SubAgentRunPreviewViewData({
    required this.id,
    required this.agentName,
    required this.statusLabel,
    required this.statusTone,
    required this.taskPreview,
    required this.summaryPreview,
    required this.toolCountLabel,
    required this.isRunning,
  });

  final String id;
  final String agentName;
  final String statusLabel;
  final SubAgentRunPreviewTone statusTone;
  final String taskPreview;
  final String summaryPreview;
  final String toolCountLabel;
  final bool isRunning;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SubAgentRunPreviewViewData &&
            other.id == id &&
            other.agentName == agentName &&
            other.statusLabel == statusLabel &&
            other.statusTone == statusTone &&
            other.taskPreview == taskPreview &&
            other.summaryPreview == summaryPreview &&
            other.toolCountLabel == toolCountLabel &&
            other.isRunning == isRunning;
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentName,
    statusLabel,
    statusTone,
    taskPreview,
    summaryPreview,
    toolCountLabel,
    isRunning,
  );
}

enum SubAgentRunPreviewTone { neutral, active, success, danger }
