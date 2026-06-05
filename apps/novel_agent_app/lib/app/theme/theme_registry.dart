import 'package:flutter/material.dart';

import 'theme_color_tokens.dart';
import 'theme_color_token_set.dart';
import 'theme_descriptor.dart';

class ThemeRegistry {
  ThemeRegistry.builtIn() : _tokenSets = _createBuiltInTokenSets();

  final Map<String, ThemeColorTokenSet> _tokenSets;

  List<ThemeDescriptor> builtInDescriptors() {
    return _tokenSets.values
        .map((tokenSet) => tokenSet.descriptor)
        .toList(growable: false);
  }

  bool contains(String id) => _tokenSets.containsKey(id);

  ThemeColorTokenSet requireColorTokenSet(String id) {
    final tokenSet = _tokenSets[id];
    if (tokenSet == null) {
      throw StateError('Unknown theme token set: $id');
    }
    return tokenSet;
  }

  ThemeColorTokenSet light() => requireColorTokenSet('builtin.light');

  ThemeColorTokenSet dark() => requireColorTokenSet('builtin.dark');

  static Map<String, ThemeColorTokenSet> _createBuiltInTokenSets() {
    final lightColors = ThemeColorTokens(
      canvasBackground: const Color(0xFFF7F2E7),
      panelBackground: const Color(0xFFF9F6ED),
      sidebarBackground: const Color(0xFFF9F6ED),
      inputBackground: Colors.white.withValues(alpha: 0.72),
      lineColor: const Color(0xFF9FC8D6),
      lineStrongColor: const Color(0xFF2E687A),
      accentColor: const Color(0xFF2D7A8C),
      accentSoftColor: const Color(0xFFD8EEF4),
      warmColor: const Color(0xFFF8E7BE),
      warmStrongColor: const Color(0xFFC47B1C),
      dangerSoftColor: const Color(0xFFFFE5E1),
      dangerStrongColor: const Color(0xFFAF3E30),
      textColor: const Color(0xFF1E2A32),
      mutedTextColor: const Color(0xFF5E6E74),
      inverseTextColor: Colors.white,
    );
    final darkColors = ThemeColorTokens(
      canvasBackground: const Color(0xFF10161B),
      panelBackground: const Color(0xFF182127),
      sidebarBackground: const Color(0xFF141C22),
      inputBackground: const Color(0xFF202A31),
      lineColor: const Color(0xFF58727C),
      lineStrongColor: const Color(0xFF8DD2E6),
      accentColor: const Color(0xFF84C9DD),
      accentSoftColor: const Color(0xFF163744),
      warmColor: const Color(0xFF4D3821),
      warmStrongColor: const Color(0xFFE6B66C),
      dangerSoftColor: const Color(0xFF4C2723),
      dangerStrongColor: const Color(0xFFFFC0B6),
      textColor: const Color(0xFFF4F2EB),
      mutedTextColor: const Color(0xFFC0CDD2),
      inverseTextColor: const Color(0xFF0F171B),
    );

    return <String, ThemeColorTokenSet>{
      'builtin.light': ThemeColorTokenSet(
        descriptor: const ThemeDescriptor(
          id: 'builtin.light',
          label: '明亮',
          brightness: Brightness.light,
        ),
        colors: lightColors,
      ),
      'builtin.dark': ThemeColorTokenSet(
        descriptor: const ThemeDescriptor(
          id: 'builtin.dark',
          label: '偏暗',
          brightness: Brightness.dark,
        ),
        colors: darkColors,
      ),
    };
  }
}
