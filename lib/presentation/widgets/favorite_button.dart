import 'package:flutter/material.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

/// İçeriği favorilere ekleyip çıkaran, durumu **kalıcı** düğme.
///
/// Tarif/yoga/egzersiz ekranlarındaki kaydet düğmeleri eskiden yalnızca
/// snackbar gösteriyordu; kullanıcı kaydettiğini sanıyor ama hiçbir şey
/// saklanmıyordu.
class FavoriteButton extends StatefulWidget {
  /// İçeriğin kalıcı kimliği (ör. "recipe_salmon", "yoga_gentle_flow").
  final String contentId;

  /// true ise dolgulu buton, false ise app bar ikonu olarak çizilir.
  final bool expanded;

  const FavoriteButton({
    super.key,
    required this.contentId,
    this.expanded = false,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  static const FavoritesRepository _repository = FavoritesRepository();

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _repository.isFavorite(widget.contentId);
    if (!mounted) return;
    setState(() => _isFavorite = value);
  }

  Future<void> _toggle() async {
    final messenger = ScaffoldMessenger.of(context);
    final addedMessage = context.tr('recipe_favorited');
    final removedMessage = context.tr('favorite_removed');

    final nowFavorite = await _repository.toggle(widget.contentId);
    if (!mounted) return;

    setState(() => _isFavorite = nowFavorite);
    messenger.showSnackBar(
      SnackBar(content: Text(nowFavorite ? addedMessage : removedMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!widget.expanded) {
      return IconButton(
        tooltip: context.tr(
          _isFavorite ? 'favorite_remove' : 'recipe_favorite',
        ),
        icon: Icon(
          _isFavorite ? Icons.bookmark : Icons.bookmark_border,
          color: theme.colorScheme.primary,
        ),
        onPressed: _toggle,
      );
    }

    // Ekranın tek ana eylemi: degrade hap. Kaydedilmişken aynı düğme
    // çıkarmayı söylüyor; durum ikonda da (dolu kalp) görünüyor.
    return AppGradientButton(
      label: context.tr(_isFavorite ? 'favorite_remove' : 'recipe_favorite'),
      icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
      radius: AppRadius.pill,
      onPressed: _toggle,
    );
  }
}
