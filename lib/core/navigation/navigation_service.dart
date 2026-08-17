import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// NavigationService, uygulamanın herhangi bir yerinden BuildContext olmadan
/// yönlendirme yapmak için kullanılan merkezi sınıftır.
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// NavigatorState'e erişebilmek için GlobalKey
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Seçili hedefe (Named Route tabanlı) yönlendirme (Replace)
  void go(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    navigatorKey.currentContext?.goNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Seçili hedefi stack üzerine ekler (Push)
  void push(
    String routeName, {
    Map<String, String> pathParameters = const {},
    Map<String, dynamic> queryParameters = const {},
    Object? extra,
  }) {
    navigatorKey.currentContext?.pushNamed(
      routeName,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Bir önceki ekrana dön (Pop)
  void pop([Object? result]) {
    if (navigatorKey.currentContext != null &&
        navigatorKey.currentContext!.canPop()) {
      navigatorKey.currentContext!.pop(result);
    }
  }
}
