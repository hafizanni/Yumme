// lib/widgets/RestaurantCard.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yumme/map/mapScreen.dart';
import 'package:yumme/widgets/favorites_service.dart';

class RestaurantCard extends StatefulWidget {
  final String id;
  final String name;
  final String cuisine;
  final String dietary;
  final double rating;
  final String price;
  final String address;
  final String operationHours;
  final String imageUrl;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final VoidCallback onTap;

  const RestaurantCard({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.dietary,
    required this.rating,
    required this.price,
    required this.address,
    required this.operationHours,
    required this.imageUrl,
    required this.isOpen,
    required this.latitude,
    required this.longitude,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  late bool _isFav;

  @override
  void initState() {
    super.initState();
    // initialize from service
    _isFav = FavoritesService.instance.contains(widget.id);
  }

  void _toggleFavorite() {
    setState(() {
      _isFav = !_isFav;
      final svc = FavoritesService.instance;
      if (_isFav) {
        svc.add({
          'id': widget.id,
          'name': widget.name,
          'cuisine': widget.cuisine,
          'dietary': widget.dietary,
          'rating': widget.rating,
          'price': widget.price,
          'address': widget.address,
          'operationHours': widget.operationHours,
          'imageUrl': widget.imageUrl,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
        });
      } else {
        svc.remove(widget.id);
      }
    });
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
        errorWidget: (c, u, e) => const Icon(Icons.error),
      );
    }
    return Image.asset(
      imageUrl,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive width: about 90% of screen width, max 320, min 260
    final double cardWidth =
        (MediaQuery.of(context).size.width * 0.90).clamp(260.0, 320.0);
    final double cardHeight =
        (MediaQuery.of(context).size.height * 0.60).clamp(320.0, 400.0);

    return Center(
      child: SizedBox(
        width: cardWidth,
        height: cardHeight, // Limit the card height
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          color: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.08),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF8FAFF),
                    Color(0xFFE6E9F5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Allow column to shrink
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // image + OPEN/CLOSED badge
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Stack(
                      children: [
                        _buildImage(widget.imageUrl),
                        Positioned(
                          top: 8, right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.isOpen ? 'OPEN NOW' : 'CLOSED',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // name & rating
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(widget.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // cuisine • dietary • price
                            Row(
                              children: [
                                Text(widget.cuisine, style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text(widget.dietary, style: TextStyle(color: Colors.grey[600])),
                                const SizedBox(width: 8),
                                const Text('•', style: TextStyle(color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text(widget.price, style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // address & hours
                            Text(widget.address, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(widget.operationHours, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(height: 8),

                            // actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const MapScreen(),
                                        settings: RouteSettings(arguments: {
                                          'latitude': widget.latitude,
                                          'longitude': widget.longitude,
                                        }),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: const Text('View on Map'),
                                ),
                                SplashyFavoriteIcon(
                                  isFavorite: _isFav,
                                  onTap: _toggleFavorite,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Place this widget in your widgets folder or inside RestaurantCard.dart

class SplashyFavoriteIcon extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const SplashyFavoriteIcon({
    Key? key,
    required this.isFavorite,
    required this.onTap,
  }) : super(key: key);

  @override
  State<SplashyFavoriteIcon> createState() => _SplashyFavoriteIconState();
}

class _SplashyFavoriteIconState extends State<SplashyFavoriteIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 1.5)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_controller);
    _opacity = Tween<double>(begin: 0.0, end: 0.5)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
  }

  @override
  void didUpdateWidget(covariant SplashyFavoriteIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite && widget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    if (!widget.isFavorite) {
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 44 * _scale.value,
                  height: 44 * _scale.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.pinkAccent.withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
          AnimatedScale(
            scale: widget.isFavorite ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.isFavorite ? Colors.pinkAccent : Colors.grey[400],
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
