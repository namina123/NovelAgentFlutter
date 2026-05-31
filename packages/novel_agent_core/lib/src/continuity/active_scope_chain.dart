import 'continuation_scope.dart';

class ActiveScopeChain {
  const ActiveScopeChain({
    this.activeScope,
    this.scopes = const <ContinuationScope>[],
  });

  final ContinuationScope? activeScope;
  final List<ContinuationScope> scopes;

  List<String> get scopeIds {
    return scopes.map((scope) => scope.id).toList(growable: false);
  }
}
