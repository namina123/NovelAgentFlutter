import 'dart:io';

class SystemProxyResolver {
  const SystemProxyResolver({
    Future<String> Function(String name)? registryValueReader,
  }) : _registryValueReader = registryValueReader;

  final Future<String> Function(String name)? _registryValueReader;

  Future<String> resolveFor(Uri uri) async {
    // 中文注释: 代理解析集中在一个适配器里，保证网关层只关心“是否有代理策略”而不关心平台细节。
    if (Platform.isWindows) {
      final windowsProxy = await _resolveWindowsProxy(uri);
      if (windowsProxy.isNotEmpty) {
        return windowsProxy;
      }
    }
    return HttpClient.findProxyFromEnvironment(
      uri,
      environment: Platform.environment,
    );
  }

  Future<String> _resolveWindowsProxy(Uri uri) async {
    final proxyEnabled = await _queryRegistryValue('ProxyEnable');
    final proxyServer = await _queryRegistryValue('ProxyServer');
    if (_isEnabledValue(proxyEnabled) && proxyServer.trim().isNotEmpty) {
      final matched = _proxyFromServerValue(proxyServer, uri.scheme);
      if (matched.isNotEmpty) {
        return matched;
      }
    }
    return '';
  }

  Future<String> _queryRegistryValue(String name) async {
    final injectedReader = _registryValueReader;
    if (injectedReader != null) {
      return injectedReader(name);
    }
    try {
      final result = await Process.run('reg', <String>[
        'query',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
        '/v',
        name,
      ]);
      if (result.exitCode != 0) {
        return '';
      }
      final output = '${result.stdout}';
      final lines = output.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith(name)) {
          continue;
        }
        final parts = trimmed.split(RegExp(r'\s{2,}'));
        if (parts.length >= 3) {
          return parts.last.trim();
        }
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  bool _isEnabledValue(String value) {
    final clean = value.trim().toLowerCase();
    if (clean.isEmpty) {
      return false;
    }
    if (clean == '0' || clean == '0x0' || clean == '0x00000000') {
      return false;
    }
    final normalized = clean.startsWith('0x') ? clean.substring(2) : clean;
    final parsedHex = int.tryParse(normalized, radix: 16);
    if (parsedHex != null) {
      return parsedHex != 0;
    }
    final parsedInt = int.tryParse(clean);
    if (parsedInt != null) {
      return parsedInt != 0;
    }
    return true;
  }

  String _proxyFromServerValue(String value, String scheme) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (!trimmed.contains('=')) {
      return _normalizeProxyDirective(trimmed);
    }
    final entries = trimmed.split(';');
    String fallback = '';
    for (final entry in entries) {
      final parts = entry.split('=');
      if (parts.length != 2) {
        continue;
      }
      final key = parts.first.trim().toLowerCase();
      final currentValue = parts.last.trim();
      if (currentValue.isEmpty) {
        continue;
      }
      if (key == scheme.toLowerCase()) {
        return _normalizeProxyDirective(currentValue);
      }
      if (fallback.isEmpty &&
          (key == 'http' || key == 'https' || key == 'socks')) {
        fallback = _normalizeProxyDirective(currentValue);
      }
    }
    return fallback;
  }

  String _normalizeProxyDirective(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('PROXY ') || upper.startsWith('SOCKS ')) {
      return trimmed;
    }
    return 'PROXY $trimmed';
  }
}
