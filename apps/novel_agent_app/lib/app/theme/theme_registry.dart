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
      canvasBackground: const Color(0xFFEEF3F9),
      panelBackground: const Color(0xFFF7FAFD),
      sidebarBackground: const Color(0xFFE6EDF5),
      inputBackground: const Color(0xFFFBFCFE),
      lineColor: const Color(0xFFC7D1DE),
      lineStrongColor: const Color(0xFF46647F),
      accentColor: const Color(0xFF2C68D2),
      accentSoftColor: const Color(0xFFD9E6FF),
      warmColor: const Color(0xFFF1E5CB),
      warmStrongColor: const Color(0xFF956F3F),
      dangerSoftColor: const Color(0xFFF9E0E4),
      dangerStrongColor: const Color(0xFFAF4758),
      textColor: const Color(0xFF172231),
      // 中文注释: 由 #617287（对侧栏/画布底色约 4.1:1，小字号不达 WCAG AA）加深到
      // #52606F（约 6:1+），让 10–11pt 的次级标签在低质屏幕上也可读。暗色主题不受影响。
      mutedTextColor: const Color(0xFF52606F),
      inverseTextColor: Colors.white,
    );
    final darkColors = ThemeColorTokens(
      canvasBackground: const Color(0xFF070B14),
      panelBackground: const Color(0xFF101826),
      sidebarBackground: const Color(0xFF0B1220),
      inputBackground: const Color(0xFF0E1728),
      lineColor: const Color(0xFF233149),
      lineStrongColor: const Color(0xFF7FA6FF),
      accentColor: const Color(0xFF4D7CFE),
      accentSoftColor: const Color(0xFF162543),
      warmColor: const Color(0xFF3D3221),
      warmStrongColor: const Color(0xFFD6A96A),
      dangerSoftColor: const Color(0xFF3D1F28),
      dangerStrongColor: const Color(0xFFFF8EA1),
      textColor: const Color(0xFFF3F7FF),
      mutedTextColor: const Color(0xFF9EACC7),
      inverseTextColor: const Color(0xFF050810),
    );

    return <String, ThemeColorTokenSet>{
      'builtin.light': ThemeColorTokenSet(
        descriptor: const ThemeDescriptor(
          id: 'builtin.light',
          label: '云昼',
          brightness: Brightness.light,
        ),
        colors: lightColors,
      ),
      'builtin.dark': ThemeColorTokenSet(
        descriptor: const ThemeDescriptor(
          id: 'builtin.dark',
          label: '深空',
          brightness: Brightness.dark,
        ),
        colors: darkColors,
      ),
    };
  }
}
