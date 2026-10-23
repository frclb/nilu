import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';

/// Kayıt ekranındaki bölümlerin başlığı: küçük gül simge ve başlık.
///
/// Bölümler ayrı dosyalarda; başlık biçimi tek yerde dursun ki biri
/// değişince diğerleri ondan ayrışmasın.
class LogSectionHeader extends StatelessWidget {
  const LogSectionHeader({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.tokens.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
