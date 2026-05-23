import 'dart:io';

const String _skillTemplate = '''---
name: {skill_name}
description: [待完成：完整且信息丰富的说明，描述技能的功能、使用时机和触发场景。]
version: 1
activation_hints:
  - [待完成：触发提示]
inputs:
  - [待完成：输入]
outputs:
  - [待完成：输出]
required_capabilities: []
optional_capabilities: []
safe_without_tools: true
resource_hints:
  scripts: []
  references: []
  assets: []
preferred_output: [待完成：期望输出]
---

# {skill_title}

## 概述

[待完成：1-2 句话解释此技能能实现什么]

## 使用时机

1. [待完成]

## 工作流程

### 第一步：理解目标

[待完成]

### 第二步：组织资源

[待完成]

### 第三步：产出结果

[待完成]

## 资源使用

### scripts/

[待完成：哪些步骤适合脚本化]

### references/

[待完成：哪些细节应放参考资料]

### assets/

[待完成：是否需要模板、图片、示例工程等素材]
''';

const String _exampleScript = '''import 'dart:io';

void main(List<String> args) {
  // 中文注释: 这是技能自带的示例 Dart 脚本，占位展示 scripts/ 的组织方式。
  stdout.writeln('这是 {skill_name} 的示例脚本。');
}
''';

const String _exampleReference = '''# {skill_title} 参考文档

把较长、按需读取的资料放在这里，而不是全部塞进 SKILL.md。
''';

const String _exampleAsset = '''此文件用于提示 assets/ 可放模板、图片、图标、示例工程等最终输出素材。''';

Future<void> main(List<String> args) async {
  // 中文注释: 该脚本用于初始化标准技能目录结构，方便把技能快速沉淀成可分发包。
  if (args.length < 3 || args[1] != '--path') {
    _printUsage();
    exit(1);
  }
  final skillName = args.first.trim();
  final outputRoot = args[2].trim();
  if (!_isValidSkillName(skillName)) {
    stderr.writeln('技能名称必须为小写字母、数字和连字符，且不能连续或首尾为连字符。');
    exit(1);
  }
  final skillDir = Directory(outputRoot).absolute.uri.resolve('$skillName/').toFilePath(
        windows: Platform.isWindows,
      );
  final targetDirectory = Directory(skillDir);
  if (await targetDirectory.exists()) {
    stderr.writeln('技能目录已存在：$skillDir');
    exit(1);
  }
  await targetDirectory.create(recursive: true);
  final title = _titleCase(skillName);
  await File('${targetDirectory.path}${Platform.pathSeparator}SKILL.md').writeAsString(
    _skillTemplate
        .replaceAll('{skill_name}', skillName)
        .replaceAll('{skill_title}', title),
  );
  final scriptsDir = Directory('${targetDirectory.path}${Platform.pathSeparator}scripts');
  final referencesDir = Directory('${targetDirectory.path}${Platform.pathSeparator}references');
  final assetsDir = Directory('${targetDirectory.path}${Platform.pathSeparator}assets');
  await scriptsDir.create();
  await referencesDir.create();
  await assetsDir.create();
  await File('${scriptsDir.path}${Platform.pathSeparator}example.dart').writeAsString(
    _exampleScript.replaceAll('{skill_name}', skillName),
  );
  await File('${referencesDir.path}${Platform.pathSeparator}guide.md').writeAsString(
    _exampleReference.replaceAll('{skill_title}', title),
  );
  await File('${assetsDir.path}${Platform.pathSeparator}example_asset.txt').writeAsString(
    _exampleAsset,
  );
  stdout.writeln("技能 '$skillName' 已初始化：${targetDirectory.path}");
}

void _printUsage() {
  stdout.writeln('用法：dart init_skill.dart <技能名称> --path <输出目录>');
}

bool _isValidSkillName(String value) {
  return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(value);
}

String _titleCase(String skillName) {
  return skillName
      .split('-')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
