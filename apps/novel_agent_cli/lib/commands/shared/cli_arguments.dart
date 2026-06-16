class CliArguments {
  const CliArguments(this.args);

  final List<String> args;

  String? value(String name) {
    // 中文注释: 统一的 flag 读取入口同时支持 `--flag value` 与 `--flag=value`，避免各命令重复扫描 token。
    for (var index = 0; index < args.length; index += 1) {
      final token = args[index];
      if (token == name) {
        if (index + 1 >= args.length) {
          return null;
        }
        final next = args[index + 1].trim();
        if (_looksLikeFlag(next)) {
          return null;
        }
        return next;
      }
      if (token.startsWith('$name=')) {
        return token.substring(name.length + 1).trim();
      }
    }
    return null;
  }

  List<String> values(String name) {
    // 中文注释: 重复 option 读取集中在共享 parser，适合 import / source 这类多值参数。
    final result = <String>[];
    for (var index = 0; index < args.length; index += 1) {
      final token = args[index];
      if (token == name) {
        if (index + 1 >= args.length) {
          continue;
        }
        final next = args[index + 1].trim();
        if (_looksLikeFlag(next)) {
          continue;
        }
        if (next.isNotEmpty) {
          result.add(next);
        }
        index += 1;
        continue;
      }
      if (token.startsWith('$name=')) {
        final value = token.substring(name.length + 1).trim();
        if (value.isNotEmpty) {
          result.add(value);
        }
      }
    }
    return result;
  }

  bool has(String name) {
    // 中文注释: 布尔 flag 支持显式出现即为真，便于 `--no-save` / `--list-strategies` 这类开关统一处理。
    for (final token in args) {
      if (token == name || token.startsWith('$name=')) {
        return true;
      }
    }
    return false;
  }

  bool boolValue(String name, bool fallback) {
    // 中文注释: 布尔参数支持无值开关和显式值两种写法，兼容 CLI 常见使用习惯。
    for (var index = 0; index < args.length; index += 1) {
      final token = args[index];
      if (token == name) {
        if (index + 1 >= args.length) {
          return true;
        }
        final next = args[index + 1].trim();
        if (_looksLikeFlag(next)) {
          return true;
        }
        return _parseBool(next, fallback);
      }
      if (token.startsWith('$name=')) {
        return _parseBool(token.substring(name.length + 1), fallback);
      }
    }
    return fallback;
  }

  int intValue(String name, int fallback) {
    // 中文注释: 数值参数统一由共享 parser 兜底，命令层只关心解析结果而不是 token 扫描细节。
    final raw = value(name);
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }
    return int.tryParse(raw.trim()) ?? fallback;
  }

  String positionalText() {
    // 中文注释: 非 flag 文本统一视为位置参数，供 prompt / path 这类快速调用路径复用。
    final parts = <String>[];
    for (var index = 0; index < args.length; index += 1) {
      final token = args[index];
      if (_looksLikeFlag(token)) {
        if (token.contains('=')) {
          continue;
        }
        if (index + 1 < args.length && !_looksLikeFlag(args[index + 1])) {
          index += 1;
        }
        continue;
      }
      parts.add(token);
    }
    return parts.join(' ').trim();
  }

  List<String> unknownFlags(Set<String> knownFlags) {
    // 中文注释: 轻量未知参数校验用于共享测试和后续帮助提示，不在这里引入重型解析器。
    final result = <String>[];
    for (final token in args) {
      if (!_looksLikeFlag(token)) {
        continue;
      }
      final flagName = token.contains('=')
          ? token.substring(0, token.indexOf('='))
          : token;
      if (!knownFlags.contains(flagName)) {
        result.add(flagName);
      }
    }
    return result;
  }

  List<String> withoutFlags(Set<String> flagNames) {
    // 中文注释: 全局输出开关会在 bootstrap 层统一剥离，避免子命令把协议级 flag 当成未知参数。
    final result = <String>[];
    for (var index = 0; index < args.length; index += 1) {
      final token = args[index];
      if (!_looksLikeFlag(token)) {
        result.add(token);
        continue;
      }
      final flagName = token.contains('=')
          ? token.substring(0, token.indexOf('='))
          : token;
      if (flagNames.contains(flagName)) {
        continue;
      }
      result.add(token);
    }
    return result;
  }

  bool _parseBool(String value, bool fallback) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    if (normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on') {
      return true;
    }
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no' ||
        normalized == 'off') {
      return false;
    }
    return fallback;
  }

  bool _looksLikeFlag(String token) {
    return token.startsWith('-') && token != '-';
  }
}
