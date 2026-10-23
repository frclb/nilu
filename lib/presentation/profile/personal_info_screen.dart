import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/content_illustration.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/profile_repository.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import 'widgets/settings_surface.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ProfileRepository _repository = const ProfileRepository();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final name = await _repository.getName();
    final email = await _repository.getEmail();
    final birthDate = await _repository.getBirthDate();
    if (!mounted) return;
    setState(() {
      _nameController.text = name ?? '';
      _emailController.text = email ?? '';
      _birthDate = birthDate;
      _isLoading = false;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final savedMessage = context.tr('personal_info_saved');

    await _repository.save(
      name: _nameController.text,
      email: _emailController.text,
      birthDate: _birthDate,
    );

    messenger.showSnackBar(SnackBar(content: Text(savedMessage)));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('personal_info_title'),
        onBack: () => context.pop(),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      // Baş harf yazdıkça güncelleniyor: kullanıcı neyin
                      // kaydedileceğini görsün.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _nameController,
                        builder: (context, value, _) {
                          final ad = value.text.trim();
                          return Column(
                            children: [
                              ExcludeSemantics(
                                child: InitialAvatar(name: ad, size: 88),
                              ),
                              if (ad.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  ad,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.3,
                                        color: theme.colorScheme.primary,
                                      ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SettingsCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              context,
                              label: context.tr('personal_info_name'),
                              hint: context.tr('personal_info_name_hint'),
                              controller: _nameController,
                              icon: Icons.badge_outlined,
                            ),
                            const SizedBox(height: 18),
                            _buildTextField(
                              context,
                              label: context.tr('personal_info_email'),
                              hint: context.tr('personal_info_email_hint'),
                              controller: _emailController,
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return null; // İsteğe bağlı alan
                                }
                                final valid = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(text);
                                return valid
                                    ? null
                                    : context.tr('personal_info_email_invalid');
                              },
                            ),
                            const SizedBox(height: 18),
                            _buildBirthDateField(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppGradientButton(
                        label: context.tr('save'),
                        icon: Icons.done_all_rounded,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  /// Alanın üstündeki küçük etiket.
  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.tokens.textMuted,
      ),
    ),
  );

  /// Kartın beyazından ayrışan alan zemini.
  Color _fieldFill(BuildContext context) =>
      context.tokens.brandTint.withAlpha(170);

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.tokens.text,
          ),
          decoration: InputDecoration(
            hintText: hint,
            fillColor: _fieldFill(context),
            suffixIcon: Icon(icon, size: 20, color: context.tokens.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField(BuildContext context) {
    final t = context.tokens;
    final value = _birthDate;
    final text = value == null
        ? context.tr('personal_info_birthdate_hint')
        : '${value.day.toString().padLeft(2, '0')}/'
              '${value.month.toString().padLeft(2, '0')}/${value.year}';
    final radius = BorderRadius.circular(AppRadius.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, context.tr('personal_info_birthdate')),
        Material(
          color: _fieldFill(context),
          // Kenar, temadaki metin alanlarınınkiyle aynı.
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side:
                Theme.of(
                  context,
                ).inputDecorationTheme.enabledBorder?.borderSide ??
                BorderSide(color: t.border),
          ),
          child: InkWell(
            onTap: _pickBirthDate,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                // Metin ve simge, üstteki metin alanlarındakiyle aynı
                // hizada.
                padding: const EdgeInsetsDirectional.fromSTEB(22, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: value == null ? t.textFaint : t.text,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: t.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
