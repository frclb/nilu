import 'package:flutter/material.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/route_names.dart';
import '../../localization/app_localizations.dart';
import '../../localization/relative_time.dart';
import '../../domain/view_models/partner_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../domain/services/partner_suggestion_engine.dart';
import '../../design_system/app_layout.dart';

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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = context.watch<PartnerViewModel>();

    final bgColor = context.tokens.background;
    final surfaceColor = context.tokens.surface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Marka pembesi sabit yazılıydı; premium tema çeşitleri bu ekranda
    // uygulanmıyordu.
    final warmAccent = context.tokens.flowSoft;
    final textMainColor = context.tokens.text;
    final textMutedColor = context.tokens.textMuted;
    final borderColor = context.tokens.border;
    final warmBg = context.tokens.brandTint;

    // Pulse animasyonu tetikle
    if (vm.hasNewUpdate) {
      _triggerPulse();
      Future.microtask(() => vm.clearNewUpdateFlag());
    }

    if (!vm.isLoaded) {
      return Scaffold(
        backgroundColor: bgColor,
        body: AppContentWidth(
          child: Center(child: CircularProgressIndicator(color: primaryColor)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          // Partner'ın adı hiçbir yerde saklanmıyor; burada `partnerId`
          // kullanılıyordu ve kullanıcıya ham UUID gösteriliyordu
          // ("a3f2b8c1-... Durumu"). Ad alanı eklenene kadar genel başlık.
          context.tr('pv_header_title'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textMainColor,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textMainColor),
            onPressed: () => context.pushNamed(RouteNames.partnerShareSettings),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(
          context,
          vm,
          isDark,
          bgColor,
          surfaceColor,
          primaryColor,
          warmAccent,
          textMainColor,
          textMutedColor,
          borderColor,
          warmBg,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PartnerViewModel vm,
    bool isDark,
    Color bgColor,
    Color surfaceColor,
    Color primaryColor,
    Color warmAccent,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
    Color warmBg,
  ) {
    // ── Edge State: Bağlantı Yok ──
    if (!vm.isConnected) {
      return _NotConnectedState(
        primaryColor: primaryColor,
        textMainColor: textMainColor,
        textMutedColor: textMutedColor,
      );
    }

    // ── Edge State: Paylaşım Kapalı ──
    if (!vm.isSharingEnabled) {
      return _SharingDisabledState(
        primaryColor: primaryColor,
        warmAccent: warmAccent,
        textMainColor: textMainColor,
        textMutedColor: textMutedColor,
      );
    }

    // ── Edge State: Veri Yok ──
    if (!vm.hasData) {
      return _EmptyDataState(
        primaryColor: primaryColor,
        warmAccent: warmAccent,
        textMainColor: textMainColor,
        textMutedColor: textMutedColor,
      );
    }

    // ── Normal State ──
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () async {
        // ViewModel'daki yenileme metodunu çağır (Firestore üzerinden tekrar okur)
        // refreshStatus şu an mevcut değilse stream kendisi dinlediği için bekleyebiliriz veya stream'i resetletebiliriz.
        // PartnerViewModel stream tabanlı olduğu için sadece gecikme ekliyoruz, akış zaten realtime.
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // ── Header ──
            _buildHeader(
              context,
              vm,
              textMainColor,
              textMutedColor,
              primaryColor,
            ),
            const SizedBox(height: 20),
            // ── Stale Data Warning ──
            if (vm.isDataStale) _buildStaleWarning(warmAccent, textMutedColor),
            // ── Ana Kart — Şu An Ne Hissediyor? ──
            _buildMainFeelingCard(
              context,
              vm,
              isDark,
              surfaceColor,
              primaryColor,
              warmAccent,
              textMainColor,
              textMutedColor,
              borderColor,
              warmBg,
            ),
            const SizedBox(height: 20),
            // ── Akıllı Öneriler ──
            _buildSuggestions(
              context,
              vm,
              isDark,
              surfaceColor,
              primaryColor,
              warmAccent,
              textMainColor,
              textMutedColor,
              borderColor,
            ),
            const SizedBox(height: 20),
            // ── Son Güncelleme ──
            _buildLastUpdated(context, vm, textMutedColor),
            const SizedBox(height: 20),
            // ── Geçmiş (Collapsible) ──
            _buildHistory(
              context,
              vm,
              isDark,
              surfaceColor,
              primaryColor,
              textMainColor,
              textMutedColor,
              borderColor,
            ),
            const SizedBox(height: 20),
            // ── Kontroller ──
            _buildControls(
              context,
              vm,
              isDark,
              surfaceColor,
              primaryColor,
              warmAccent,
              textMainColor,
              textMutedColor,
              borderColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader(
    BuildContext context,
    PartnerViewModel vm,
    Color textMainColor,
    Color textMutedColor,
    Color primaryColor,
  ) {
    final userName =
        context.read<UserViewModel>().partnerId ?? context.tr('partner_label');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar + İsim
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withAlpha(180)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textMainColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('pv_header_subtitle'),
          style: TextStyle(fontSize: 13, color: textMutedColor),
        ),
        const SizedBox(height: 8),
        // Bağlantı durumu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.tokens.success.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: context.tokens.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('pv_connected'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.tokens.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // STALE DATA WARNING
  // ══════════════════════════════════════════════════════════════

  Widget _buildStaleWarning(Color warmAccent, Color textMutedColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.tokens.warning.withAlpha(30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.tokens.warning.withAlpha(76)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 16, color: context.tokens.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('pv_old_data_warning'),
                style: TextStyle(fontSize: 12, color: context.tokens.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ANA KART — ŞU AN NE HİSSEDİYOR?
  // ══════════════════════════════════════════════════════════════

  Widget _buildMainFeelingCard(
    BuildContext context,
    PartnerViewModel vm,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Color warmAccent,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
    Color warmBg,
  ) {
    final status = vm.currentStatus!;
    final desireKey = PartnerSuggestionEngine.getDesireKey(status.sexualDesire);
    final desireText = desireKey == null ? '' : context.tr(desireKey);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnimation.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.tokens.brandTint, context.tokens.flowTint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? warmAccent.withAlpha(30)
                : primaryColor.withAlpha(25),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withAlpha(isDark ? 15 : 12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 16,
                    color: warmAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('pv_feeling_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textMainColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Cinsel İstek (doğal dil) ──
            if (desireText.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      desireText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textMainColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ── Sevgi İhtiyaçları ──
            if (status.affectionNeeds.isNotEmpty) ...[
              Row(
                children: [
                  Text('❤️', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('pv_affection_label'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMutedColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: status.affectionNeeds.map((need) {
                  final needKey = PartnerSuggestionEngine.getNeedKey(need);
                  final needText = needKey == null ? need : context.tr(needKey);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppScrim.frost(8) : AppScrim.frost(180),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppScrim.frost(12)
                            : primaryColor.withAlpha(20),
                      ),
                    ),
                    child: Text(
                      needText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppScrim.frost(220)
                            : primaryColor.withAlpha(200),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // AKILLI ÖNERİLER — NE YAPABİLİRSİN?
  // ══════════════════════════════════════════════════════════════

  Widget _buildSuggestions(
    BuildContext context,
    PartnerViewModel vm,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Color warmAccent,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    final suggestions = vm.suggestions;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: warmAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              context.tr('pv_suggestions_title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textMainColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...suggestions.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: AppScrim.veil(26),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(s.key),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textMainColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SON GÜNCELLEME
  // ══════════════════════════════════════════════════════════════

  Widget _buildLastUpdated(
    BuildContext context,
    PartnerViewModel vm,
    Color textMutedColor,
  ) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: textMutedColor),
          const SizedBox(width: 6),
          Text(
            '${context.tr('pv_last_updated')}: '
            '${context.relativeTime(vm.timeSinceLastUpdate)}',
            style: TextStyle(fontSize: 12, color: textMutedColor),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // GEÇMİŞ (COLLAPSIBLE)
  // ══════════════════════════════════════════════════════════════

  Widget _buildHistory(
    BuildContext context,
    PartnerViewModel vm,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    if (vm.historyList.length <= 1) return const SizedBox.shrink();

    // İlk girdi mevcut durum, gerisini göster
    final pastEntries = vm.historyList.skip(1).take(3).toList();
    if (pastEntries.isEmpty) return const SizedBox.shrink();

    return _CollapsibleHistory(
      entries: pastEntries,
      isDark: isDark,
      surfaceColor: surfaceColor,
      primaryColor: primaryColor,
      textMainColor: textMainColor,
      textMutedColor: textMutedColor,
      borderColor: borderColor,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // KONTROLLER (Mute / Disconnect)
  // ══════════════════════════════════════════════════════════════

  Widget _buildControls(
    BuildContext context,
    PartnerViewModel vm,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Color warmAccent,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Bildirim Kontrol
          InkWell(
            onTap: () => vm.toggleMuteNotifications(),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    vm.notificationsMuted
                        ? Icons.notifications_off_outlined
                        : Icons.notifications_active_outlined,
                    size: 20,
                    color: textMutedColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vm.notificationsMuted
                          ? context.tr('pv_unmute')
                          : context.tr('pv_mute'),
                      style: TextStyle(fontSize: 14, color: textMainColor),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: textMutedColor),
                ],
              ),
            ),
          ),
          Divider(color: borderColor, height: 16),
          // Bağlantı Kes
          InkWell(
            onTap: () => _showDisconnectDialog(context, vm, primaryColor),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.link_off, size: 20, color: warmAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('pv_disconnect'),
                      style: TextStyle(fontSize: 14, color: warmAccent),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: textMutedColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Disconnect Dialog ──
  void _showDisconnectDialog(
    BuildContext context,
    PartnerViewModel vm,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('pv_disconnect_title')),
        content: Text(context.tr('pv_disconnect_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('pv_cancel')),
          ),
          TextButton(
            onPressed: () async {
              // Buradaki tek çağrı `vm.disconnect()` idi ve o yalnızca
              // bellekteki durumu temizliyordu: `partnerId` hâlâ
              // SharedPreferences'ta, `isPartner` hâlâ true kalıyordu.
              // Uygulama yeniden açıldığında partner bağlı geliyor, uzak
              // taraftaki bağlantı da hiç kopmuyordu — oysa uyarı metni
              // "bu işlem geri alınamaz" diyor.
              final userViewModel = ctx.read<UserViewModel>();
              final router = GoRouter.of(ctx);

              Navigator.pop(ctx);

              vm.disconnect();
              await userViewModel.setPartnerState(
                isPartner: false,
                partnerId: null,
              );

              // Partner modundan çıkıldı; kabuk artık partner ekranlarını
              // göstermemeli.
              router.goNamed(RouteNames.onboarding);
            },
            // Bağlantıyı kesmek geri alınamaz; iki eylem aynı görünüyordu ve
            // hangisinin yıkıcı olduğu okunmuyordu.
            child: Text(
              context.tr('pv_disconnect_confirm'),
              style: TextStyle(
                color: context.tokens.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// COLLAPSIBLE HISTORY
// ══════════════════════════════════════════════════════════════

class _CollapsibleHistory extends StatefulWidget {
  final List entries;
  final bool isDark;
  final Color surfaceColor;
  final Color primaryColor;
  final Color textMainColor;
  final Color textMutedColor;
  final Color borderColor;

  const _CollapsibleHistory({
    required this.entries,
    required this.isDark,
    required this.surfaceColor,
    required this.primaryColor,
    required this.textMainColor,
    required this.textMutedColor,
    required this.borderColor,
  });

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: widget.textMutedColor),
                const SizedBox(width: 8),
                Text(
                  context.tr('pv_history_title'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textMainColor,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: widget.textMutedColor,
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
            children: widget.entries.map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: widget.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: widget.textMutedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(entry.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.textMutedColor,
                        ),
                      ),
                      const Spacer(),
                      if (entry.sexualDesire.isNotEmpty &&
                          entry.sexualDesire != '')
                        Text('🔥', style: const TextStyle(fontSize: 14)),
                      if (entry.affectionNeeds.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '❤️ ${entry.affectionNeeds.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.textMutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EDGE STATE: BAĞLANTI YOK
// ══════════════════════════════════════════════════════════════

class _NotConnectedState extends StatelessWidget {
  final Color primaryColor;
  final Color textMainColor;
  final Color textMutedColor;

  const _NotConnectedState({
    required this.primaryColor,
    required this.textMainColor,
    required this.textMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_off,
                size: 36,
                color: primaryColor.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('pv_no_connection_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pv_no_connection_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textMutedColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed(RouteNames.partner),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: Text(context.tr('pv_invite_partner')),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EDGE STATE: PAYLAŞIM KAPALI
// ══════════════════════════════════════════════════════════════

class _SharingDisabledState extends StatelessWidget {
  final Color primaryColor;
  final Color warmAccent;
  final Color textMainColor;
  final Color textMutedColor;

  const _SharingDisabledState({
    required this.primaryColor,
    required this.warmAccent,
    required this.textMainColor,
    required this.textMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: warmAccent.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.visibility_off_outlined,
                size: 36,
                color: warmAccent.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('pv_sharing_disabled_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pv_sharing_disabled_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textMutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// EDGE STATE: VERİ YOK
// ══════════════════════════════════════════════════════════════

class _EmptyDataState extends StatelessWidget {
  final Color primaryColor;
  final Color warmAccent;
  final Color textMainColor;
  final Color textMutedColor;

  const _EmptyDataState({
    required this.primaryColor,
    required this.warmAccent,
    required this.textMainColor,
    required this.textMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: warmAccent.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 36,
                color: warmAccent.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('pv_empty_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pv_empty_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textMutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
