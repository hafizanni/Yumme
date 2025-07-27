import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RestaurantDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final void Function(LatLng userLoc, LatLng restLoc, String name)? onGetDirections;

  const RestaurantDetailsSheet({
    required this.restaurant,
    this.onGetDirections,
    Key? key,
  }) : super(key: key);

  @override
  State<RestaurantDetailsSheet> createState() => _RestaurantDetailsSheetState();
}

class _RestaurantDetailsSheetState extends State<RestaurantDetailsSheet> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final gradientColors = [
      const Color(0xFFFA8BFF),
      const Color(0xFF2BD2FF),
      const Color(0xFF2BFF88),
    ];

    final restaurant = widget.restaurant;
    final reviews = restaurant['reviews'] as List<dynamic>?;

    // 1) Compute 80% of the screen‐height so we don’t overflow:
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      child: Padding(
        // Add a little horizontal margin so it isn't edge-to-edge
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: ConstrainedBox(
          // Constrain the height to at most 80% of the screen:
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              // clipRRect so the gradient rounds corners underneath
              borderRadius: BorderRadius.circular(28),
              child: SingleChildScrollView(
                // If content is taller than 80%, user can scroll
                child: Card(
                  color: Colors.white.withOpacity(0.90),
                  elevation: 18,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Floating handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          restaurant['CompleteStoreName'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating, Cuisine, Dietary, Price
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              (restaurant['AverageRating'] as num?)?.toStringAsFixed(1) ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Text(restaurant['FoodType'] ?? '', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            const Text('•'),
                            const SizedBox(width: 8),
                            Text(restaurant['Dietary'] ?? '', style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            const Text('•'),
                            const SizedBox(width: 8),
                            Text(restaurant['price'] ?? '', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // About section
                        const Text(
                          'About',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['description'] ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        // Address section
                        const Text(
                          'Address',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['address'] ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        // Operating Hours
                        const Text(
                          'Operating Hours',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['OperationHours'] ?? '',
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        ),
                        const SizedBox(height: 14),
                        // Reviews (if any)
                        if (reviews != null && reviews.isNotEmpty) ...[
                          const Text(
                            'Reviews',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...reviews.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(
                                  '• $r',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                              )),
                          const SizedBox(height: 10),
                        ],
                        // Action Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _loading ? null : _getDirections,
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Get Directions'),
                          ),
                        ),
                        SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getDirections() async {
    setState(() => _loading = true);
    late Position position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() => _loading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _loading = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      return;
    }

    final lat = (widget.restaurant['Latitude'] as num?)?.toDouble();
    final lng = (widget.restaurant['Longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant location not available')));
      return;
    }

    if (widget.onGetDirections != null) {
      widget.onGetDirections!(
        LatLng(position.latitude, position.longitude),
        LatLng(lat, lng),
        widget.restaurant['CompleteStoreName'] ?? 'Restaurant',
      );
    }
    setState(() => _loading = false);
  }

  addDirectionHistory({required int userId, required String destination, required double distance}) {}
}
