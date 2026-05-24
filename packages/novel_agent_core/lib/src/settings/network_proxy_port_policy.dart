class NetworkProxyPortPolicy {
  const NetworkProxyPortPolicy._();

  static const int minPort = 1;
  static const int maxPort = 65535;

  static String normalizeText(String rawValue) {
    // 中文注释: 代理端口统一限制在固定合法范围内，避免不同宿主各自散写边界处理。
    final parsed = int.tryParse(rawValue.trim());
    if (parsed == null) {
      return '';
    }
    final normalized = parsed.clamp(minPort, maxPort);
    return '$normalized';
  }
}
