import 'package:flutter/material.dart';
import '../../../design_system/content_illustration.dart';

class YogaVideoPlayer extends StatelessWidget {
  /// Gerçek fotoğraf tedarik edilince buraya bir adres verilir; adres ölürse
  /// ya da cihaz çevrimdışıysa uygulama içinde çizilen illüstrasyona düşer.
  /// Daha önce burada Google'ın geçici mockup adresi sabit olarak duruyordu.
  final String? imageUrl;

  const YogaVideoPlayer({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
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
              SafeNetworkImage(
                url: imageUrl,
                fallback: const ContentIllustration(
                  seed: 'yoga_hero',
                  icon: Icons.self_improvement,
                ),
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

              // Ortada bir oynat düğmesi duruyordu ama hiçbir yere
              // bağlı değildi — uygulamada video diye bir şey yok. Video
              // oynatıcı görüntüsü vermek, olmayan bir içerik vaat ediyordu.
              // Rehberli seans aşağıdaki "Başlat" düğmesinden açılıyor.
            ],
          ),
        ),
      ),
    );
  }
}
