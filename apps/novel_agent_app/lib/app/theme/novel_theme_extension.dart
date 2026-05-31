import 'package:flutter/material.dart';

import 'theme_token_set.dart';

@immutable
class NovelThemeExtension extends ThemeExtension<NovelThemeExtension> {
  const NovelThemeExtension({required this.tokenSet});

  final ThemeTokenSet tokenSet;

  @override
  ThemeExtension<NovelThemeExtension> copyWith({ThemeTokenSet? tokenSet}) {
    return NovelThemeExtension(tokenSet: tokenSet ?? this.tokenSet);
  }

  @override
  ThemeExtension<NovelThemeExtension> lerp(
    covariant ThemeExtension<NovelThemeExtension>? other,
    double t,
  ) {
    if (other is! NovelThemeExtension || t < 0.5) {
      return this;
    }
    return other;
  }
}
