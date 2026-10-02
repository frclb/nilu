import 'package:flutter/material.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';

/// Günlük kayıt ekranını açan "+" düğmesi.
///
/// Döngü, gebelik ve lohusa panolarında aynı düğme. Önce yalnızca döngü
/// ana ekranındaydı: gebe ya da lohusa kullanıcının kayıt ekranına hiç
/// girişi yoktu — gebelik belirtileri, tansiyon ve kilo, gebelikte kanama
/// uyarısı yazılmış ama ulaşılamaz durumdaydı.
class LogEntryFab extends StatelessWidget {
  const LogEntryFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    key: const Key('log_entry_fab'),
    heroTag: 'home_fab',
    onPressed: () => NavigationService().push(RouteNames.logEntry),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    elevation: 4,
    shape: const CircleBorder(),
    child: const Icon(Icons.add, size: 32),
  );
}
