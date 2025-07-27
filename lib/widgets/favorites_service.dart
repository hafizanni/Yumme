// lib/services/favorites_service.dart

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  final List<Map<String, dynamic>> _favorites = [];

  /// Read-only view of your favorites
  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);

  bool contains(String id) =>
      _favorites.any((r) => r['id'] == id);

  void add(Map<String, dynamic> restaurant) {
    if (!contains(restaurant['id'] as String)) {
      _favorites.add(restaurant);
    }
  }

  void remove(String id) {
    _favorites.removeWhere((r) => r['id'] == id);
  }
}
