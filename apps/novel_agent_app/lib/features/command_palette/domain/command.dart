/// 命令系统领域模型。
///
/// 命令面板（Ctrl+K）的全部命令都抽象成 [AppCommand]：一个全局唯一 id、
/// 用户可见标题、分类、可选副标题/关键词/快捷键提示，以及一个自包含的执行闭包。
///
/// 设计约束：
/// - [invoke] 闭包自行捕获所需控制器，不接收面板传入的上下文，保证命令可在任何位置触发。
/// - [isEnabled] 仅用于面板过滤；返回 false 时命令不展示也不可执行。
/// - [keywords] 仅参与检索匹配，不会展示给用户；应包含同义词、英文别名等。
library;

/// 命令分类。决定命令在面板里的分组与默认排序顺序。
enum CommandCategory {
  /// 跳转到某个页面。
  navigation('导航'),
  /// 与文档/文件相关的操作。
  document('文档'),
  /// 切换面板、视图等可见性。
  view('视图'),
  /// 其它创作台操作。
  operations('操作'),
  /// 主题、外观相关。
  theme('主题');

  const CommandCategory(this.label);

  /// 用户可见的分类标签。
  final String label;
}

/// 命令面板中的一条可执行命令。
class AppCommand {
  const AppCommand({
    required this.id,
    required this.title,
    required this.category,
    required this.invoke,
    this.subtitle,
    this.keywords = const <String>[],
    this.shortcutLabel,
    this.isEnabled,
  });

  /// 全局唯一 id，采用点分命名空间（如 `nav.workbench`、`doc.save`）。
  final String id;

  /// 用户可见标题。
  final String title;

  /// 副标题 / 补充说明，可选；展示在标题下方灰色小字。
  final String? subtitle;

  /// 所属分类。
  final CommandCategory category;

  /// 检索关键词（不展示）。
  final List<String> keywords;

  /// 快捷键展示文本（如 `Ctrl+S`），仅用于提示，不参与实际按键绑定。
  final String? shortcutLabel;

  /// 是否可用；为 null 视为恒可用。
  final bool Function()? isEnabled;

  /// 执行命令。
  final void Function() invoke;

  /// 当前是否可用（[isEnabled] 为 null 时视为恒可用）。
  bool get enabled => isEnabled?.call() ?? true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppCommand && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
