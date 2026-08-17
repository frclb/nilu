import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../design_system/app_colors.dart';

class PartnerSupportScreen extends StatefulWidget {
  const PartnerSupportScreen({super.key});

  @override
  State<PartnerSupportScreen> createState() => _PartnerSupportScreenState();
}

class _PartnerSupportScreenState extends State<PartnerSupportScreen>
    with SingleTickerProviderStateMixin {
  // Checkbox states
  bool _task1Completed = true; // Sıcak Su Torbası
  bool _task2Completed = false; // Magnezyum Desteği

  // Fade-in animation controller
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors from HTML design
    final primaryColor = const Color(0xFFEE2B4E);
    final bgColor = isDark
        ? const Color(0xFF12090A)
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? const Color(0xFF241114) : Colors.white;
    final textMainColor = isDark ? Colors.white : AppColors.textMainSlate;
    final textMutedColor = isDark
        ? Colors.white.withAlpha(153)
        : AppColors.textMutedSlate;
    final borderColor = isDark
        ? Colors.white.withAlpha(12)
        : AppColors.borderSlateLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? bgColor.withAlpha(204)
            : bgColor.withAlpha(229),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          context.tr('partner_support_title'),
          style: TextStyle(
            color: textMainColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textMainColor),
            onPressed: () {
              context.pushNamed(RouteNames.partnerShareSettings);
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          physics: const BouncingScrollPhysics(),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: FractionalTranslation(
                  translation: _slideAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildContextHeader(
                  context,
                  primaryColor,
                  textMainColor,
                  textMutedColor,
                ),
                const SizedBox(height: 32),
                _buildProgressSummary(
                  context,
                  isDark,
                  primaryColor,
                  surfaceColor,
                  textMainColor,
                  textMutedColor,
                  borderColor,
                ),
                const SizedBox(height: 32),
                _buildPhysicalSupportSection(
                  context,
                  isDark,
                  primaryColor,
                  surfaceColor,
                  textMainColor,
                  textMutedColor,
                  borderColor,
                ),
                const SizedBox(height: 32),
                _buildEmotionalSupportSection(
                  context,
                  isDark,
                  primaryColor,
                  surfaceColor,
                  textMainColor,
                  textMutedColor,
                  borderColor,
                ),
                const SizedBox(height: 32),
                _buildKnowledgeCorner(
                  context,
                  isDark,
                  primaryColor,
                  surfaceColor,
                  textMainColor,
                  textMutedColor,
                  borderColor,
                ),
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Context Header (Day & Phase) ──
  Widget _buildContextHeader(
    BuildContext context,
    Color primaryColor,
    Color textMainColor,
    Color textMutedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(51),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop, color: primaryColor, size: 14),
              const SizedBox(width: 6),
              Text(
                (context.tr('partner_support_day_1')).toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.tr('partner_support_phase'),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textMainColor,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('partner_support_phase_desc'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMutedColor,
          ),
        ),
      ],
    );
  }

  // ── Progress Summary (Horizontal Scroll) ──
  Widget _buildProgressSummary(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          // NOT: Burada eskiden "Günlük Skor 85/100" kartı vardı. Bu değer
          // hiçbir veriden hesaplanmıyordu — her kullanıcıya aynı uydurma
          // sağlık skoru gösteriliyordu. Kişiye özel sahte sağlık verisi hem
          // yanıltıcı hem de mağaza incelemesinde red sebebi olduğu için
          // kaldırıldı. Gerçek bir skor modeli eklendiğinde geri getirilebilir.
          _buildSummaryCard(
            context: context,
            isDark: isDark,
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: context.tr('partner_support_water_need'),
            // Kişiye özel değil, genel günlük su tüketimi önerisi.
            value: context.tr('partner_support_water_value'),
            surfaceColor: surfaceColor,
            textMainColor: textMainColor,
            textMutedColor: textMutedColor,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color surfaceColor,
    required Color textMainColor,
    required Color textMutedColor,
    required Color borderColor,
  }) {
    return Container(
      width: 140, // fixed min-width equivalent
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Glow for icon
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withAlpha(25),
              ),
              child: BackdropFilter(
                filter: _buildBlurFilter(),
                child: const SizedBox(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: textMutedColor),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textMainColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for blur
  dynamic _buildBlurFilter() {
    return const ColorFilter.mode(Colors.transparent, BlendMode.srcOver);
    // ImageFilter.blur was causing some web issues occasionally without dart:ui.
    // BoxShadow approach is safer in pure flutter. The glowing circle serves enough purpose.
  }

  // ── Physical Support Section ──
  Widget _buildPhysicalSupportSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.tr('partner_support_physical'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
              ],
            ),
            Text(
              '2 ${context.tr('tasks')}', // Example dynamically counted if needed
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTaskCard(
          isDark: isDark,
          surfaceColor: surfaceColor,
          primaryColor: primaryColor,
          textMainColor: textMainColor,
          textMutedColor: textMutedColor,
          borderColor: borderColor,
          title: context.tr('partner_support_task_1'),
          desc: context.tr('partner_support_task_1_desc'),
          isCompleted: _task1Completed,
          onTap: () {
            setState(() {
              _task1Completed = !_task1Completed;
            });
          },
        ),
        const SizedBox(height: 12),
        _buildTaskCard(
          isDark: isDark,
          surfaceColor: surfaceColor,
          primaryColor: primaryColor,
          textMainColor: textMainColor,
          textMutedColor: textMutedColor,
          borderColor: borderColor,
          title: context.tr('partner_support_task_2'),
          desc: context.tr('partner_support_task_2_desc'),
          isCompleted: _task2Completed,
          onTap: () {
            setState(() {
              _task2Completed = !_task2Completed;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required bool isDark,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textMainColor,
    required Color textMutedColor,
    required Color borderColor,
    required String title,
    required String desc,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark ? surfaceColor.withAlpha(127) : surfaceColor)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? primaryColor.withAlpha(76) : borderColor,
          ),
          boxShadow: isDark || isCompleted
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? primaryColor
                      : (isDark
                            ? Colors.white.withAlpha(51)
                            : Colors.grey.shade300),
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            // Texts
            Expanded(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isCompleted ? 0.5 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textMainColor,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: textMutedColor,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Emotional Support Section ──
  Widget _buildEmotionalSupportSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  context.tr('partner_support_emotional'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textMainColor,
                  ),
                ),
              ],
            ),
            Text(
              '2 ${context.tr('suggestions')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTipCard(
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          icon: Icons.chair,
          iconColor: Colors.purple,
          title: context.tr('partner_support_tip_1'),
          desc: context.tr('partner_support_tip_1_desc'),
          textMainColor: textMainColor,
          textMutedColor: textMutedColor,
        ),
        const SizedBox(height: 12),
        _buildTipCard(
          isDark: isDark,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          icon: Icons.record_voice_over,
          iconColor: Colors.pink,
          title: context.tr('partner_support_tip_2'),
          desc: context.tr('partner_support_tip_2_desc'),
          textMainColor: textMainColor,
          textMutedColor: textMutedColor,
        ),
      ],
    );
  }

  Widget _buildTipCard({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required Color textMainColor,
    required Color textMutedColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textMainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: textMutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Knowledge Corner (Gradient Box) ──
  Widget _buildKnowledgeCorner(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb, color: primaryColor, size: 22),
            const SizedBox(width: 8),
            Text(
              context.tr('partner_support_knowledge'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMainColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [surfaceColor, primaryColor.withAlpha(25)]
                  : [Colors.white, primaryColor.withAlpha(12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withAlpha(25)),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: primaryColor.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.science, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('partner_support_hormone'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textMainColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('partner_support_hormone_desc'),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: textMutedColor,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('article_coming_soon')),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('read_more'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
