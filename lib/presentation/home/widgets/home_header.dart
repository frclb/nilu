import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../domain/view_models/user_view_model.dart';
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
    final isDark = theme.brightness == Brightness.dark;
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
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withAlpha(12) : Colors.white,
                border: Border.all(
                  color: theme
                      .colorScheme
                      .secondary, // primary/50 in dark, secondary-pink in light
                  width: 2,
                ),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA5FKMkf2k4fb7FSXjTldPpWAWGko7c9UcqpvVUiX9WwOjTdAIKPTTKFjQvCEvmivxh8DxaW02P-_Ik32mpQlVoyTVpEbc9FrNRUQxeSGEqCKe75uN0BBQmF1gIBP9j1hV_ltMVfPwBYWtxy6MHD0mwWIkbcVmVEzg-KvN8hNF4GDYeF06I3sNlm8qSD8f44tolT-t8m5P3h33BHfqvevoGaHtqsZuTFPgvA6RTdmLurQ-_HPjea5EsDOO6ymUqcvQvAu6WCI5xzsA',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.grey,
              ), // Fallback icon
            ),
          ),
        ],
      ),
    );
  }
}
