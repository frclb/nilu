import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../design_system/content_illustration.dart';

/// Hareketlerin fotoğrafı ve sessiz, döngülü mini videosu.
///
/// Dosyalar uygulamaya gömülü (`assets/exercise/`): Pexels'ten, ticari
/// kullanıma ücretsiz lisansla; videolar 12 saniyelik döngülere kırpılıp
/// sesleri çıkarıldı, fotoğrafların konum ve cihaz bilgileri silindi.
/// Ağa gidilmiyor: içerik çevrimdışı da görünüyor.
///
/// Lisans, görüntüdeki kişilerin uygulamayı önerdiği izlenimini
/// yasaklıyor: yanlarına yalnızca nötr poz anlatımı yazılıyor.
abstract final class ExerciseMedia {
  static String photo(String key) => 'assets/exercise/$key.jpg';
  static String video(String key) => 'assets/exercise/$key.mp4';

  /// Seansın kapak fotoğrafı.
  static const String cover = 'assets/exercise/cover.jpg';
}

/// Hareketin fotoğrafı; dosya yoksa uygulama içinde çizilen illüstrasyon.
class ExercisePhoto extends StatelessWidget {
  const ExercisePhoto({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      // Görsel bir dekor değil, hareketin kendisi: ekran okuyucu adını
      // yanındaki başlıktan okuyor.
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) =>
          ContentIllustration(seed: asset, icon: Icons.self_improvement),
    );
  }
}

/// Sessiz, döngülü mini video. Yüklenene kadar ve oynatılamazsa fotoğraf.
///
/// "Hareketi azalt" açıksa video oynamıyor; fotoğraf yeterli.
class ExerciseClip extends StatefulWidget {
  const ExerciseClip({super.key, required this.mediaKey, this.playing = true});

  final String mediaKey;

  /// Seans duraklatılınca video da duruyor.
  final bool playing;

  @override
  State<ExerciseClip> createState() => _ExerciseClipState();
}

class _ExerciseClipState extends State<ExerciseClip> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _open(widget.mediaKey);
  }

  @override
  void didUpdateWidget(ExerciseClip old) {
    super.didUpdateWidget(old);
    if (old.mediaKey != widget.mediaKey) {
      _close();
      if (!MediaQuery.disableAnimationsOf(context)) _open(widget.mediaKey);
    } else if (old.playing != widget.playing) {
      _applyPlaying();
    }
  }

  Future<void> _open(String key) async {
    final controller = VideoPlayerController.asset(
      ExerciseMedia.video(key),
      // Arka plandaki müziği kesmesin: sessiz bir döngü.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
    } catch (e) {
      // Video açılamıyorsa fotoğraf kalıyor.
      debugPrint('Exercise clip unavailable ($key): $e');
      if (identical(_controller, controller)) _controller = null;
      await controller.dispose();
      return;
    }
    if (!mounted || !identical(_controller, controller)) {
      await controller.dispose();
      return;
    }
    setState(() => _ready = true);
    _applyPlaying();
  }

  void _applyPlaying() {
    final c = _controller;
    if (c == null || !_ready) return;
    widget.playing ? c.play() : c.pause();
  }

  void _close() {
    final c = _controller;
    _controller = null;
    _ready = false;
    c?.dispose();
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExercisePhoto(asset: ExerciseMedia.photo(widget.mediaKey)),
        if (c != null && _ready)
          // Fotoğrafın üstünde yumuşakça beliriyor: yükleme anı sıçramasın.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, v, child) => Opacity(opacity: v, child: child),
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
