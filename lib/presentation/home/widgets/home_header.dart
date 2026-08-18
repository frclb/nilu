import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../design_system/content_illustration.dart';
import '../../../localization/app_localizations.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await const ProfileRepository().getName();
    if (!mounted) return;
    setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userViewModel = context.watch<UserViewModel>();
    final isPartner = userViewModel.isPartner;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPartner
                    ? (context.tr('home_greeting_partner'))
                    : context.tr('home_greeting'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // Ad profilden gelir; girilmemişse nötr bir hitap kullanılır.
              if (!isPartner)
                Text(
                  (_name?.isNotEmpty ?? false)
                      ? _name!
                      : context.tr('home_greeting_no_name'),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: theme.colorScheme.primary, // #551b26 in light
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: () {
              NavigationService().go(RouteNames.profile);
            },
            // Avatar da uzak bir adresten geliyordu — üstelik her kullanıcıya
            // **aynı** fotoğrafı gösteriyordu. Kullanıcının kendi adının baş
            // harfi hem doğru hem çevrimdışı çalışıyor.
            child: InitialAvatar(name: _name),
          ),
        ],
      ),
    );
  }
}
