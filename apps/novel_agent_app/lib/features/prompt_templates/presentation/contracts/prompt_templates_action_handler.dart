import '../models/prompt_templates_view_data.dart';

abstract class PromptTemplatesActionHandler {
  void onPromptTemplatesBackRequested();

  void onPromptTemplatesRefreshRequested();

  void onPromptTemplatesTemplateSelected(String templateId);

  void onPromptTemplatesNewRequested();

  void onPromptTemplatesSaveRequested(PromptTemplateEditorRequestViewData request);

  void onPromptTemplatesPreviewRequested(
    PromptTemplateEditorRequestViewData request,
  );

  void onPromptTemplatesRestoreRequested(String templateId);

  void onPromptTemplatesDeleteRequested(String templateId);
}
