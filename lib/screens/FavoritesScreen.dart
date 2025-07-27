
import 'package:flutter/material.dart';
import 'package:yumme/widgets/favorites_service.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = FavoritesService.instance.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favs.isEmpty
          ? const Center(child: Text('No favorites yet.'))
          : ListView.builder(
              itemCount: favs.length,
              itemBuilder: (_, i) {
                final r = favs[i];
                return ListTile(
                  leading: r['imageUrl'] != null
                      ? Image.network(r['imageUrl'], width: 56, fit: BoxFit.cover)
                      : const Icon(Icons.restaurant),
                  title: Text(r['name']),
                  subtitle: Text(r['address']),
                  onTap: () {
                    Navigator.pushNamed(context, '/map', arguments: {
                      'latitude': r['latitude'],
                      'longitude': r['longitude'],
                    });
                  },
                );
              },
            ),
    );
  }
}
