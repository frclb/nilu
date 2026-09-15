import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/profile_repository.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.tokens.surfaceAlt,
      appBar: AppBar(
        title: Text(
          context.tr('personal_info_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: context.tokens.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.tokens.surfaceAlt,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.tokens.text,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: AppContentWidth(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTextField(
                      context,
                      label: context.tr('personal_info_name'),
                      hint: context.tr('personal_info_name_hint'),
                      controller: _nameController,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
                      label: context.tr('personal_info_email'),
                      hint: context.tr('personal_info_email_hint'),
                      controller: _emailController,
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null; // İsteğe bağlı alan
                        final valid = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(text);
                        return valid
                            ? null
                            : context.tr('personal_info_email_invalid');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildBirthDateField(context, isDark),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('save'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.tokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(fontSize: 16, color: context.tokens.text),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: context.tokens.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.tokens.border),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField(BuildContext context, bool isDark) {
    final value = _birthDate;
    final text = value == null
        ? context.tr('personal_info_birthdate_hint')
        : '${value.day.toString().padLeft(2, '0')}/'
              '${value.month.toString().padLeft(2, '0')}/${value.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('personal_info_birthdate'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.tokens.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.tokens.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: value == null
                        ? (context.tokens.textMuted)
                        : (context.tokens.text),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: context.tokens.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
