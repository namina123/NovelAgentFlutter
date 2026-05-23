import 'dart:io';

void main(List<String> args) {
  // 中文注释: 该脚本做技能包的轻量结构校验，适合在打包前快速检查基础问题。
  if (args.length != 1) {
    stdout.writeln('用法：dart quick_validate.dart <技能目录>');
    exit(1);
  }
  final result = validateSkillDirectory(args.first);
  stdout.writeln(result.message);
  exit(result.ok ? 0 : 1);
}

ValidationResult validateSkillDirectory(String directoryPath) {
  // 中文注释: 这里检查 SKILL.md、frontmatter 和 name/description 等最基本分发前提。
  final skillDirectory = Directory(directoryPath);
  if (!skillDirectory.existsSync()) {
    return const ValidationResult(false, '未找到技能目录。');
  }
  final skillFile = File('${skillDirectory.path}${Platform.pathSeparator}SKILL.md');
  if (!skillFile.existsSync()) {
    return const ValidationResult(false, '未找到 SKILL.md。');
  }
  final content = skillFile.readAsStringSync();
  if (!content.startsWith('---')) {
    return const ValidationResult(false, '未找到 YAML 前置元数据。');
  }
  final match = RegExp(r'^---\n([\s\S]*?)\n---').firstMatch(content);
  if (match == null) {
    return const ValidationResult(false, '前置元数据格式无效。');
  }
  final frontmatter = match.group(1) ?? '';
  final nameMatch = RegExp(r'^name:\s*(.+)$', multiLine: true).firstMatch(frontmatter);
  final descriptionMatch = RegExp(r'^description:\s*(.+)$', multiLine: true).firstMatch(frontmatter);
  if (nameMatch == null) {
    return const ValidationResult(false, "前置元数据中缺少 'name'。");
  }
  if (descriptionMatch == null) {
    return const ValidationResult(false, "前置元数据中缺少 'description'。");
  }
  final name = nameMatch.group(1)?.trim() ?? '';
  if (!RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(name)) {
    return ValidationResult(false, "名称 '$name' 应为连字符格式（仅限小写字母、数字和连字符）。");
  }
  final description = descriptionMatch.group(1)?.trim() ?? '';
  if (description.contains('<') || description.contains('>')) {
    return const ValidationResult(false, '描述不能包含尖括号（< 或 >）。');
  }
  return const ValidationResult(true, '技能验证通过！');
}

class ValidationResult {
  const ValidationResult(this.ok, this.message);

  final bool ok;
  final String message;
}
