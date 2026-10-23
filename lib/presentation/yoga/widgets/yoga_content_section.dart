import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/session_plan.dart';
import '../../../localization/app_localizations.dart';

/// Yoga akışının gövdesi: başlık, süre ve seviye, faydalar, pozlar.
///
/// Pozlar ve süreleri `SessionPlan.yoga` ile aynı: "Başlat"a basınca
/// zamanlayıcı burada yazan sırayı ve süreleri izliyor.
class YogaContentSection extends StatelessWidget {
  const YogaContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final steps = SessionPlan.yoga.steps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık ──
          Semantics(
            header: true,
            child: Text(
              context.tr('yoga_title'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                height: 1.15,
                color: primary,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Süre ve seviye ──
          // Burada üçüncü bir kutu "120 kcal" yazıyordu. Sabit bir sayıydı:
          // kalori kişinin kilosuna, hızına ve pozda ne kadar kaldığına göre
          // değişir, uygulamanın bunların hiçbirini ölçecek verisi yok.
          // Tahmini bir sayıyı ölçüm gibi göstermek yerine kutuyu kaldırdım.
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.schedule,
                  value: context.tr(
                    'duration_minutes',
                    params: {'n': '${SessionPlan.yoga.total.inMinutes}'},
                  ),
                  label: context.tr('yoga_stat_duration'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.signal_cellular_alt,
                  value: context.tr('yoga_level_beginner'),
                  label: context.tr('yoga_stat_level'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Faydalar ──
          _SectionTitle(context.tr('yoga_benefits_title')),
          const SizedBox(height: 12),
          _BenefitCard(
            icon: Icons.favorite,
            title: context.tr('yoga_benefit_cramps'),
            description: context.tr('yoga_benefit_cramps_desc'),
          ),
          const SizedBox(height: 10),
          _BenefitCard(
            icon: Icons.self_improvement,
            title: context.tr('yoga_benefit_calm'),
            description: context.tr('yoga_benefit_calm_desc'),
          ),
          const SizedBox(height: 10),
          _BenefitCard(
            icon: Icons.bedtime,
            title: context.tr('yoga_benefit_sleep'),
            description: context.tr('yoga_benefit_sleep_desc'),
          ),
          const SizedBox(height: 28),

          // ── Pozlar ──
          _SectionTitle(context.tr('yoga_poses_title')),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _PoseCard(
              index: i + 1,
              name: context.tr(steps[i].nameKey),
              description: context.tr(steps[i].descriptionKey),
              duration: context.tr(
                'duration_minutes',
                params: {'n': '${steps[i].duration.inMinutes}'},
              ),
            ),
          ],
          // Burada bir "Eğitmen" bölümü vardı: fotoğraf, "Elif Yılmaz —
          // Yoga Eğitmeni" ve bir "Profili Gör" bağlantısı. Böyle bir kişi
          // yok, profil ekranı da yok — bağlantı "yakında" uyarısı basıyordu.
          // Sağlık içeriğini var olmayan birine atfetmek, ölü bir düğmeden
          // daha kötü.
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 18,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: t.brandTint.withAlpha(170),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          AppIconTile(
            icon: icon,
            size: 34,
            circle: true,
            color: t.secondary,
            background: t.surface,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: t.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 42,
            color: t.secondary,
            background: t.surfaceAlt,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({
    required this.index,
    required this.name,
    required this.description,
    required this.duration,
  });

  final int index;
  final String name;
  final String description;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppTag(
                      label: duration,
                      background: t.surfaceAlt,
                      foreground: t.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
