import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class YogaVideoPlayer extends StatelessWidget {
  final String imageUrl;

  const YogaVideoPlayer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: isDark
                        ? AppColors.surfaceWarmDark
                        : Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.self_improvement,
                        size: 48,
                        color: isDark ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  );
                },
              ),

              // Gradient Overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xCC000000), // 80%
                      Color(0x33000000), // 20%
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Play Button
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(76),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom label
              Positioned(
                bottom: 12,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(102),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Text(
                        context.tr('preview'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
