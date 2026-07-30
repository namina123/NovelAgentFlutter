import 'dart:math' as math;

import '../domain/command.dart';

/// 带得分的命令命中结果，用于面板排序。
class ScoredCommand {
  const ScoredCommand(this.command, this.score);

  /// 命中的命令。
  final AppCommand command;

  /// 相关性得分，越高越靠前。
  final double score;
}

/// 按 [query] 检索命令并按相关性降序排序。
///
/// 检索策略（得分从高到低）：
///   1. 标题完全相等
///   2. 标题前缀匹配
///   3. 标题包含（词边界优先于普通包含）
///   4. 关键词完全相等
///   5. 关键词包含
///   6. 标题子序列模糊匹配（覆盖拉丁字母缩写，如 `tsk`→`task`）
///   7. 关键词子序列模糊匹配
///
/// - 空 query 返回全部可用命令，按「分类 → 标题」稳定排序。
/// - 不可用命令（[AppCommand.enabled] 为 false）一律不返回。
/// - 中日韩文本走「包含」路径即可命中（子序列主要服务拉丁字母）。
List<ScoredCommand> searchCommands(
  Iterable<AppCommand> commands,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    final sorted = commands.where((AppCommand c) => c.enabled).toList()
      ..sort(_compareByCategoryThenTitle);
    return sorted
        .map((AppCommand c) => ScoredCommand(c, 0))
        .toList(growable: false);
  }

  final results = <ScoredCommand>[];
  for (final command in commands) {
    if (!command.enabled) continue;
    final score = _scoreCommand(command, normalized);
    if (score > 0) {
      results.add(ScoredCommand(command, score));
    }
  }
  results.sort((ScoredCommand a, ScoredCommand b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    return a.command.title.compareTo(b.command.title);
  });
  return results;
}

int _compareByCategoryThenTitle(AppCommand a, AppCommand b) {
  final byCategory = a.category.index.compareTo(b.category.index);
  if (byCategory != 0) return byCategory;
  return a.title.compareTo(b.title);
}

/// 计算单条命令相对 [query]（已小写化）的得分；无任何匹配返回 0。
double _scoreCommand(AppCommand command, String query) {
  final title = command.title.toLowerCase();
  double best = 0;

  if (title == query) {
    return 1000;
  }
  if (title.startsWith(query)) {
    best = math.max(best, 600);
  } else if (title.contains(query)) {
    // 词边界（空格、顿号、冒号）紧跟查询串的包含，相关性高于普通包含。
    best = math.max(
      best,
      _isWordBoundaryContain(title, query) ? 350 : 300,
    );
  } else if (_isSubsequence(title, query)) {
    best = math.max(best, 45);
  }

  for (final keyword in command.keywords) {
    final k = keyword.toLowerCase();
    if (k == query) {
      best = math.max(best, 250);
    } else if (k.contains(query)) {
      best = math.max(best, 120);
    } else if (_isSubsequence(k, query)) {
      best = math.max(best, 18);
    }
  }

  return best;
}

bool _isWordBoundaryContain(String haystack, String needle) {
  // 中文注释: 查询串出现在标题的非首部、且前一个字符是分隔符时，视为词边界命中。
  final idx = haystack.indexOf(needle);
  if (idx <= 0) return false;
  final prev = haystack[idx - 1];
  return prev == ' ' || prev == '、' || prev == '：' || prev == ':';
}

/// [needle] 是否为 [haystack] 的子序列（保持顺序，不要求连续）。
bool _isSubsequence(String haystack, String needle) {
  if (needle.isEmpty) return true;
  var matched = 0;
  for (var i = 0; i < haystack.length && matched < needle.length; i++) {
    if (haystack.codeUnitAt(i) == needle.codeUnitAt(matched)) {
      matched++;
    }
  }
  return matched == needle.length;
}
