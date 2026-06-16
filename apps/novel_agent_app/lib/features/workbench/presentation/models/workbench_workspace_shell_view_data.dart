import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_long_task_summary_view_data.dart';
import 'project_agent_group_panel_view_data.dart';

@immutable
class WorkbenchWorkspaceShellViewData {
  const WorkbenchWorkspaceShellViewData({
    required this.projectName,
    required this.projectSubtitle,
    this.projectTypeId = '',
    this.projectTypeTransitionAvailability =
        const EntryAvailabilityDecision.hiddenContract(
          entryId: 'workspace.transition_project_type',
        ),
    required this.resourceCount,
    required this.activeDocumentTitle,
    required this.activeDocumentPath,
    required this.activeDocumentBody,
    required this.activeDocumentDirty,
    this.activeDocumentBufferedDraft = false,
    required this.activeDocumentCanRender,
    this.activeDocumentIdentityLabel = '',
    this.activeDocumentStateLabel = '',
    this.activeDocumentStatusLabel = '',
    required this.generationStatus,
    required this.contextSummary,
    required this.workflowTitle,
    required this.workflowDescription,
    required this.modelLabel,
    required this.agentGroupLabel,
    required this.primaryAgentLabel,
    required this.toolCoreStatus,
    required this.pendingOptionCount,
    required this.subAgentRunCount,
    required this.isGenerating,
    required this.projectAgentGroupPanel,
    this.projectLongTaskSummary,
  });

  final String projectName;
  final String projectSubtitle;
  final String projectTypeId;
  final EntryAvailabilityDecision projectTypeTransitionAvailability;
  final int resourceCount;
  final String activeDocumentTitle;
  final String activeDocumentPath;
  final String activeDocumentBody;
  final bool activeDocumentDirty;
  final bool activeDocumentBufferedDraft;
  final bool activeDocumentCanRender;
  final String activeDocumentIdentityLabel;
  final String activeDocumentStateLabel;
  final String activeDocumentStatusLabel;
  final String generationStatus;
  final String contextSummary;
  final String workflowTitle;
  final String workflowDescription;
  final String modelLabel;
  final String agentGroupLabel;
  final String primaryAgentLabel;
  final String toolCoreStatus;
  final int pendingOptionCount;
  final int subAgentRunCount;
  final bool isGenerating;
  final ProjectAgentGroupPanelViewData projectAgentGroupPanel;
  final ProjectLongTaskSummaryViewData? projectLongTaskSummary;

  bool get hasActiveDocument => activeDocumentPath.trim().isNotEmpty;

  String get activeDocumentDisplayTitle {
    final title = activeDocumentTitle.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final path = activeDocumentPath.trim();
    if (path.isNotEmpty) {
      return path;
    }
    return '尚未打开文档';
  }

  String get activeDocumentExcerpt {
    final normalized = activeDocumentBody.replaceAll('\r', '').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final singleLine = normalized.replaceAll('\n', ' ');
    if (singleLine.length <= 140) {
      return singleLine;
    }
    return '${singleLine.substring(0, 140)}...';
  }
}
