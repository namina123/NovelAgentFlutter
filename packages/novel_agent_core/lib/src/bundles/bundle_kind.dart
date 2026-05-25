final class BundleKind {
  static const String projectPackage = 'novel_agent_project_package';
  static const String characterCardBundle = 'novel_agent_character_card_bundle';
  static const String styleBundle = 'novel_agent_style_bundle';
  static const String promptTemplateBundle =
      'novel_agent_prompt_template_bundle';

  static bool isSupported(String rawValue) {
    return const <String>{
      projectPackage,
      characterCardBundle,
      styleBundle,
      promptTemplateBundle,
    }.contains(rawValue.trim());
  }
}
