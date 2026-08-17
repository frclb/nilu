import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_colors.dart';

class PartnerQrGenScreen extends StatefulWidget {
  const PartnerQrGenScreen({super.key});

  @override
  State<PartnerQrGenScreen> createState() => _PartnerQrGenScreenState();
}

class _PartnerQrGenScreenState extends State<PartnerQrGenScreen> {
  String? _myId;

  @override
  void initState() {
    super.initState();
    _ensureMyId();
  }

  Future<void> _ensureMyId() async {
    // Kimlik üretimi tek bir yerde: UserViewModel.ensureMyId().
    // Firebase varsa anonim UID, yoksa yerel UUID döner.
    final id = await context.read<UserViewModel>().ensureMyId();
    if (!mounted) return;
    setState(() {
      _myId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final primaryColor = theme.colorScheme.primary;
    final textMainColor = isDark ? Colors.white : AppColors.textMainSlate;
    final textMutedColor = isDark
        ? const Color(0xFFB3A2A5)
        : AppColors.textMutedSlate;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMainColor),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.tr('partner_qr_gen_title'),
          style: TextStyle(
            color: textMainColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _myId == null
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.qr_code_2, size: 60, color: primaryColor),
                  ),
                  const SizedBox(height: 24),

                  // Title and instruction
                  Text(
                    context.tr('partner_qr_gen_header'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textMainColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('partner_qr_gen_desc'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: textMutedColor,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Premium QR Code Card with glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative Glow Background
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(51),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      // QR Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withAlpha(
                              (isDark ? 0.05 : 0.40 * 255).toInt(),
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withAlpha(76)
                                  : primaryColor.withAlpha(20),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _myId!,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.transparent,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ID Display (hidden optionally or stylized)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _myId!.substring(
                                  0,
                                  8,
                                ), // Show short slice just as reference
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: textMutedColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Share Button Alternative
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _myId!));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('partner_qr_gen_code_copied'),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textMainColor,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withAlpha(51)
                            : Colors.grey.shade300,
                      ),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: Text(
                      context.tr('partner_qr_gen_copy_code'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
