import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/pairing_token.dart';
import '../../domain/services/partner_suggestion_engine.dart';
import '../../domain/view_models/partner_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/relative_time.dart';
import '../widgets/profile_avatar_button.dart';
import 'widgets/partner_ui.dart';

/// Partner rolündeki kullanıcının ana sekmesi ("Durum").
///
/// Partner yalnızca sahibin paylaşmayı seçtiği yakınlık durumunu görüyor:
/// istek düzeyi ve sevgi ihtiyaçları. Döngü verisi buraya hiç gelmiyor ve
/// ekran geliyormuş gibi konuşmuyor.
class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Pulse animasyonu (yeni güncelleme)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final vm = context.watch<PartnerViewModel>();

    // Pulse animasyonu tetikle
    if (vm.hasNewUpdate) {
      _triggerPulse();
      Future.microtask(() => vm.clearNewUpdateFlag());
    }

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Partnerin adı hiçbir yerde saklanmıyor; burada eskiden
            // `partnerId` yazıyordu ve kullanıcıya ham UUID gösteriliyordu.
            // Sekmenin adı yeterli. Ayar simgesi de yok: sahibin paylaşım
            // ayarlarında partnerin değiştirebileceği bir şey yok.
            AppBrandBar(
              title: context.tr('partner_nav_dashboard'),
              trailing: const ProfileAvatarButton(),
            ),
            Expanded(
              child: AppContentWidth(
                child: !vm.isLoaded
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildBody(context, vm),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PartnerViewModel vm) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final kod = PairingToken.confirmationCode(
      context.watch<UserViewModel>().myId ?? '',
    );
    switch (vm.state) {
      case PartnerLinkState.notConnected:
        return _StateMessage(
          icon: Icons.link_off_rounded,
          titleKey: 'pv_no_connection_title',
          descKey: 'pv_no_connection_desc',
          color: primary,
          tint: t.brandTint,
          showLeave: true,
        );
      case PartnerLinkState.unavailable:
        return _StateMessage(
          icon: Icons.cloud_off_outlined,
          titleKey: 'pv_unavailable_title',
          descKey: 'partner_unavailable',
          color: primary,
          tint: t.brandTint,
          showLeave: true,
        );
      case PartnerLinkState.awaitingApproval:
        // Onay gelene kadar kurallar okumayı reddediyor; dinleyici kendini
        // yeniden deniyor. Partner, sahibin ekranındaki kodla kendi
        // kodunu karşılaştırıyor.
        return _StateMessage(
          key: const Key('pv_awaiting'),
          icon: Icons.hourglass_top_rounded,
          titleKey: 'pv_awaiting_title',
          desc: context.tr('pv_awaiting_desc', params: {'code': kod}),
          emphasis: kod,
          color: primary,
          tint: t.brandTint,
          showLeave: true,
        );
      case PartnerLinkState.unreachable:
        return _StateMessage(
          icon: Icons.wifi_off_rounded,
          titleKey: 'pv_unreachable_title',
          descKey: 'pv_unreachable_desc',
          color: t.flowText,
          tint: t.flowTint,
          showLeave: true,
        );
      case PartnerLinkState.connected:
        if (!vm.hasData) {
          // Hiç paylaşılmamış ya da paylaşım kapatılmış: kapatınca doküman
          // siliniyor, ikisi ayırt edilemiyor ve ekran ayırt ediyormuş gibi
          // yapmıyor.
          return _StateMessage(
            key: const Key('pv_empty'),
            icon: Icons.hourglass_empty_rounded,
            titleKey: 'pv_empty_title',
            descKey: 'pv_empty_desc',
            color: t.flowText,
            tint: t.flowTint,
            showLeave: true,
          );
        }
    }

    // ── Normal durum ──
    return RefreshIndicator(
      color: primary,
      onRefresh: () async => vm.retry(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _HeaderCard(),
            const SizedBox(height: 16),
            if (vm.isDataStale) ...[
              const _StaleWarning(),
              const SizedBox(height: 16),
            ],
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: _FeelingCard(vm: vm),
            ),
            if (vm.suggestions.isNotEmpty) ...[
              const SizedBox(height: 28),
              _Suggestions(vm: vm),
            ],
            // İlk girdi mevcut durum; geçmiş yalnızca daha eskisi varsa.
            if (vm.historyList.length > 1) ...[
              const SizedBox(height: 24),
              _CollapsibleHistory(
                entries: vm.historyList.skip(1).take(3).toList(),
              ),
            ],
            const SizedBox(height: 24),
            Center(child: _LeaveButton(color: t.danger)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BAŞLIK KARTI
// ══════════════════════════════════════════════════════════════

/// Kimin durumuna bakıldığı.
///
/// Burada eskiden `partnerId` yazıyordu ve ham bir UID kullanıcıya partnerin
/// **adı** gibi gösteriliyordu ("k3Jd9QzLm2Xp..."), avatar harfi de onun ilk
/// karakterinden geliyordu. Partnerin adı hiçbir yerde saklanmadığı için ad
/// alanı eklenene kadar genel etiket ve onun baş harfi.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final userName = context.tr('partner_label');

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.mark(context),
                boxShadow: AppShadows.soft(context),
              ),
              child: Text(
                // Ad saklanmıyor; harf yerelleştirilmiş etiketten.
                context.upper(userName.characters.first),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  height: 1,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    AppTag(
                      label: context.tr('pv_connected'),
                      dotColor: t.success,
                      background: t.success.withAlpha(26),
                      foreground: t.success,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('pv_header_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(
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

// ══════════════════════════════════════════════════════════════
// ESKİ VERİ UYARISI
// ══════════════════════════════════════════════════════════════

class _StaleWarning extends StatelessWidget {
  const _StaleWarning();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.warning.withAlpha(30),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.warning.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: t.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('pv_old_data_warning'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.4, color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ANA KART — ŞU AN NE HİSSEDİYOR?
// ══════════════════════════════════════════════════════════════

class _FeelingCard extends StatelessWidget {
  const _FeelingCard({required this.vm});

  final PartnerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final on = theme.colorScheme.onPrimary;
    final status = vm.currentStatus!;
    final desireKey = PartnerSuggestionEngine.getDesireKey(status.sexualDesire);
    final desireText = desireKey == null ? '' : context.tr(desireKey);
    final guncelleme = context.relativeTime(vm.timeSinceLastUpdate);

    return Container(
      decoration: BoxDecoration(
        gradient: PartnerUi.plum(context),
        borderRadius: BorderRadius.circular(AppCard.radius),
        boxShadow: AppShadows.floating(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Köşede yumuşak bir gül ışıması.
          Positioned(
            top: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      t.secondary.withAlpha(90),
                      t.secondary.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: on.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded, size: 14, color: on),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.upper(context.tr('pv_feeling_title')),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: on,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (guncelleme.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: on.withAlpha(190),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            guncelleme,
                            semanticsLabel:
                                '${context.tr('pv_last_updated')}: $guncelleme',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: on.withAlpha(190),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Cinsel istek (doğal dil) ──
                if (desireText.isNotEmpty)
                  Text(
                    desireText,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      height: 1.2,
                      color: on,
                    ),
                  ),

                // ── Sevgi ihtiyaçları ──
                if (status.affectionNeeds.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.upper(context.tr('pv_affection_label')),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: on.withAlpha(170),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, need) in status.affectionNeeds.indexed)
                        _NeedPill(
                          text: PartnerSuggestionEngine.getNeedKey(need) == null
                              ? need
                              : context.tr(
                                  PartnerSuggestionEngine.getNeedKey(need)!,
                                ),
                          first: i == 0,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Erik kartın üstünde ihtiyaç hapı: ilki beyaz, gerisi tül.
class _NeedPill extends StatelessWidget {
  const _NeedPill({required this.text, required this.first});

  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: first ? on : on.withAlpha(36),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 13,
          fontWeight: first ? FontWeight.w700 : FontWeight.w600,
          color: first ? scheme.primary : on,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ÖNERİLER — NE YAPABİLİRSİN?
// ══════════════════════════════════════════════════════════════

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.vm});

  final PartnerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppIconTile(
              icon: Icons.lightbulb_outline_rounded,
              size: 32,
              circle: true,
              background: t.accentTint,
              color: t.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PartnerSectionTitle(context.tr('pv_suggestions_title')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final s in vm.suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.brandTint,
                      shape: BoxShape.circle,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        s.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.tr(s.key),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: t.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// GEÇMİŞ (AÇILIR)
// ══════════════════════════════════════════════════════════════

class _CollapsibleHistory extends StatefulWidget {
  const _CollapsibleHistory({required this.entries});

  final List entries;

  @override
  State<_CollapsibleHistory> createState() => _CollapsibleHistoryState();
}

class _CollapsibleHistoryState extends State<_CollapsibleHistory> {
  bool _expanded = false;

  String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$d.$mo — $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return Container(
      decoration: AppCard.decoration(t),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: t.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('pv_history_title'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 15,
                          color: t.text,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: [
                  for (final entry in widget.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppCard.dividerColor(t)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: t.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(entry.timestamp),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                          const Spacer(),
                          if (entry.sexualDesire.isNotEmpty &&
                              entry.sexualDesire != '')
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                          if (entry.affectionNeeds.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '❤️ ${entry.affectionNeeds.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
              secondChild: const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// KENAR DURUMLAR
// ══════════════════════════════════════════════════════════════

/// Bağlantı yok, sunucu yok, onay bekleniyor, ulaşılamıyor ya da paylaşılan
/// durum yok. Her birinde partner modundan çıkabilmeli: önceden "Partner
/// Davet Et" düğmesi partner sekmesini açıyor, o da bu ekrana dönüyordu.
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    super.key,
    required this.icon,
    required this.titleKey,
    this.descKey,
    this.desc,
    this.emphasis,
    required this.color,
    required this.tint,
    this.showLeave = false,
  });

  final IconData icon;
  final String titleKey;
  final String? descKey;
  final String? desc;

  /// Açıklamada kalın gösterilecek parça (doğrulama kodu).
  final String? emphasis;
  final Color color;
  final Color tint;
  final bool showLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final metin = desc ?? context.tr(descKey!);
    final govde = theme.textTheme.bodyLarge?.copyWith(
      height: 1.5,
      color: t.textMuted,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconTile(
              icon: icon,
              size: 84,
              circle: true,
              background: tint,
              color: color,
            ),
            const SizedBox(height: 24),
            Text(
              context.tr(titleKey),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            if (emphasis == null)
              Text(metin, textAlign: TextAlign.center, style: govde)
            else
              Text.rich(
                PartnerUi.emphasize(
                  metin,
                  emphasis!,
                  TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: t.text,
                  ),
                ),
                textAlign: TextAlign.center,
                style: govde,
              ),
            if (showLeave) ...[
              const SizedBox(height: 24),
              _LeaveButton(color: t.danger),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Bağlantıyı Kes": her durumda aynı düğme.
class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const Key('pv_leave'),
      onPressed: () => confirmLeavePartner(context),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      icon: const Icon(Icons.link_off_rounded, size: 18),
      label: Text(context.tr('pv_disconnect')),
    );
  }
}

/// Partner modundan çıkış: sahibin listesinden kendini çıkarır, bekleyen
/// isteği geri çeker ve bu cihazda kurulumu baştan başlatır.
///
/// Önceden yalnızca bu cihazdaki kayıt siliniyordu ve uyarı "geri
/// alınamaz" diyordu: sunucuda erişim duruyordu, yeniden bağlanmak da
/// yeni bir davetle mümkündü.
Future<void> confirmLeavePartner(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('pv_disconnect_title')),
      content: Text(ctx.tr('pv_disconnect_desc')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.tr('pv_cancel')),
        ),
        FilledButton(
          key: const Key('pv_leave_confirm'),
          style: AppTheme.dialogAction().copyWith(
            backgroundColor: WidgetStatePropertyAll(ctx.tokens.danger),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.tr('pv_disconnect_confirm')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final user = context.read<UserViewModel>();
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final failed = context.tr('pv_disconnect_failed');
  if (await user.leavePartnerRole()) {
    // Kurulum bayrağı da sıfırlandı; yönlendirici artık geri sıçratmıyor.
    router.goNamed(RouteNames.onboarding);
  } else {
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }
}
