import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({super.key, this.selectedIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userViewModel = context.watch<UserViewModel>();
    final isPartner = userViewModel.isPartner;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(127),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: isPartner
                ? _buildPartnerNavItems(context)
                : _buildStandardNavItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStandardNavItems(BuildContext context) {
    return [
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(0),
          child: _NavItem(
            icon: Icons.home_filled,
            label: context.tr('nav_home'),
            isActive: selectedIndex == 0,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(1),
          child: _NavItem(
            icon: Icons.calendar_month,
            label: context.tr('nav_calendar'),
            isActive: selectedIndex == 1,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(2),
          child: _NavItem(
            icon: Icons.auto_stories,
            label: context.tr('health_library_title'),
            isActive: selectedIndex == 2,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(3),
          child: _NavItem(
            icon: Icons.person,
            label: context.tr('nav_profile'),
            isActive: selectedIndex == 3,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPartnerNavItems(BuildContext context) {
    return [
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(0),
          child: _NavItem(
            icon: Icons.favorite,
            label: context.tr('partner_nav_dashboard'),
            isActive: selectedIndex == 0,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(1),
          child: _NavItem(
            icon: Icons.calendar_month,
            label: context.tr('partner_nav_calendar'),
            isActive: selectedIndex == 1,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(2),
          child: _NavItem(
            icon: Icons.handshake,
            label: context.tr('partner_nav_support'),
            isActive: selectedIndex == 2,
          ),
        ),
      ),
      Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap?.call(3),
          child: _NavItem(
            icon: Icons.person,
            label: context.tr('nav_profile'),
            isActive: selectedIndex == 3,
          ),
        ),
      ),
    ];
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.textTheme.labelLarge?.color ?? Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: isActive ? primary : muted, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? primary : muted,
          ),
        ),
      ],
    );
  }
}
