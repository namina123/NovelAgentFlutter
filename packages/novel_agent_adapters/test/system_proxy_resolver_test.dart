import 'package:novel_agent_adapters/src/providers/system_proxy_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('SystemProxyResolver', () {
    test(
      'ignores Windows proxy server when ProxyEnable is disabled DWORD',
      () async {
        // 中文注释: Windows 注册表常把关闭态写成 0x0；这里验证解析器不会误把关闭代理当成开启。
        final resolver = SystemProxyResolver(
          registryValueReader: (name) async {
            switch (name) {
              case 'ProxyEnable':
                return '0x0';
              case 'ProxyServer':
                return '127.0.0.1:7890';
              default:
                return '';
            }
          },
          environment: const <String, String>{},
        );

        final result = await resolver.resolveFor(
          Uri.parse('https://example.com/chat/completions'),
        );
        expect(result, anyOf(isEmpty, 'DIRECT'));
      },
    );

    test(
      'returns normalized proxy directive when Windows proxy is enabled',
      () async {
        // 中文注释: 开启代理时仍应保留当前规范化输出，供 HttpClient.findProxy 直接使用。
        final resolver = SystemProxyResolver(
          registryValueReader: (name) async {
            switch (name) {
              case 'ProxyEnable':
                return '0x1';
              case 'ProxyServer':
                return '127.0.0.1:7890';
              default:
                return '';
            }
          },
          environment: const <String, String>{},
        );

        final result = await resolver.resolveFor(
          Uri.parse('https://example.com/chat/completions'),
        );
        expect(result, 'PROXY 127.0.0.1:7890');
      },
    );
  });
}
