import 'dart:async';
import 'dart:io';

/// 把任意底层异常/错误对象映射成给用户看的一句中文。
///
/// 原则（修复"raw $error 泄漏到用户态"那类问题）：
/// - 绝不把 `error.toString()`（含 Dart 类型名 `FileSystemException` / `_TypeError`
///   / 堆栈相邻文本）直接抛到用户面前。
/// - 已知类别给具体人话（超时 / 网络 / 鉴权 / 限流 / 上下文超限 / 文件读写 / 数据格式）。
/// - 未知类别给通用兜底（"操作失败，请稍后重试"），不泄露内部细节。
/// - 排查细节走日志/trace，不在用户态堆栈。
class UserFacingErrorHumanizer {
  const UserFacingErrorHumanizer();

  /// 把 [error] 转成用户可读的一句话。[action] 用于兜底句（如"保存"/"生成"/"导入"）。
  static String humanize(
    Object? error, {
    String action = '操作',
  }) {
    if (error == null) {
      return '$action失败，请稍后重试。';
    }
    // 1. 类型精确匹配（最可靠）。
    if (error is TimeoutException) {
      return '请求超时，请检查网络或稍后重试。';
    }
    if (error is SocketException) {
      return '网络连接失败，请检查网络后重试。';
    }
    if (error is HttpException) {
      // 中文注释: HttpException 多来自网关对非 2xx 的统一抛出（消息形如 "模型请求失败(401): ..."）。
      // 按 HTTP 状态码归类，避免把 401/403/429/上下文超限/5xx 都误报成"网络请求失败"——网络其实是通的。
      return _humanizeHttpException(error);
    }
    if (error is FileSystemException) {
      return '文件读写失败，请检查路径与读写权限。';
    }
    if (error is FormatException) {
      return '数据格式异常，可能内容损坏或与当前版本不兼容。';
    }
    if (error is StateError || error is ArgumentError) {
      return '$action失败，状态或参数异常，请重试。';
    }
    // 2. 文本特征匹配（HTTP 状态码 / 常见模型侧错误，provider/gateway 多以字符串透出）。
    final text = error.toString();
    final lower = text.toLowerCase();
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return '鉴权失败，请检查 API Key 是否正确。';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return '当前账号没有访问权限（403），请检查 Key 权限。';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return '请求的资源不存在（404），请检查 baseUrl 与模型配置。';
    }
    if (lower.contains('429') ||
        lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('quota')) {
      return '请求过于频繁或额度用尽（429），请稍后重试。';
    }
    if (lower.contains('5') &&
        (lower.contains('internal server') ||
            lower.contains('bad gateway') ||
            lower.contains('service unavailable') ||
            lower.contains('server error'))) {
      return '服务端暂时异常（5xx），请稍后重试。';
    }
    if (lower.contains('context length') ||
        lower.contains('maximum context') ||
        lower.contains('context window') ||
        lower.contains('too long')) {
      return '输入内容超过模型上下文上限，请精简后重试。';
    }
    if (lower.contains('timeout') ||
        lower.contains('timed out') ||
        lower.contains('time out')) {
      return '请求超时，请稍后重试。';
    }
    if (lower.contains('socket') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable') ||
        lower.contains('failed host lookup')) {
      return '网络连接失败，请检查网络后重试。';
    }
    // 3. 通用兜底：不向用户泄露内部细节。
    return '$action失败，请稍后重试。';
  }

  static String _humanizeHttpException(HttpException error) {
    final message = error.toString();
    final codeMatch = RegExp(r'\((\d{3})\)').firstMatch(message);
    final code = codeMatch?.group(1) ?? '';
    if (code == '401') {
      return '鉴权失败，请检查 API Key 是否正确。';
    }
    if (code == '403') {
      return '当前账号没有访问权限（403），请检查 Key 权限。';
    }
    if (code == '404') {
      return '请求的资源不存在（404），请检查 baseUrl 与模型配置。';
    }
    if (code == '429') {
      return '请求过于频繁或额度用尽（429），请稍后重试。';
    }
    if (code.startsWith('5')) {
      return '服务端暂时异常（$code），请稍后重试。';
    }
    if (code.startsWith('4')) {
      return '请求被服务方拒绝（$code），请检查请求参数或模型配置。';
    }
    // 中文注释: 上下文超限常以 400 + "context length" 出现，先于通用网络失败判断。
    final lower = message.toLowerCase();
    if (lower.contains('context length') ||
        lower.contains('maximum context') ||
        lower.contains('context window') ||
        lower.contains('too long')) {
      return '输入内容超过模型上下文上限，请精简后重试。';
    }
    if (code.isEmpty) {
      return '网络请求失败，请稍后重试。';
    }
    return '网络请求失败（HTTP $code），请稍后重试。';
  }
}
