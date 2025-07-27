import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumme/widgets/RestaurantCard.dart';
import 'package:yumme/widgets/RestaurantDetailsSheet.dart';
import 'package:http/http.dart' as http;
import 'package:yumme/authentication/database/DatabaseHelper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  late final PageController _pageController;

  List<Map<String, dynamic>> restaurants = [];
  int _currentSelectedIndex = 0;
  LatLng _currentMapCenter = const LatLng(0, 0);
  double _currentZoom = 13.0;
  bool _isSatelliteView = false;
  LatLng? _currentLocation;

  // for deep‐link / “View on Map” arguments (if you ever pass in lat/lng via Navigator)
  bool _handledRouteArgs = false;
  double? _argLat, _argLng;

  // Once a route is computed:
  List<LatLng> _routePoints = [];
  double? _routeDistanceKm;
  LatLng? _routeStart;
  LatLng? _routeEnd;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentSelectedIndex);
    _loadRestaurants();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_handledRouteArgs) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null &&
          args['latitude'] is double &&
          args['longitude'] is double) {
        _argLat = args['latitude'] as double;
        _argLng = args['longitude'] as double;
      }
      _handledRouteArgs = true;
    }
  }

  Future<void> _loadRestaurants() async {
    final jsonStr = await rootBundle.loadString('assets/data/top_rated_restaurants_with_osm.json');
    final data = json.decode(jsonStr) as List<dynamic>;
    if (data.isEmpty) return;

    restaurants = data.cast<Map<String, dynamic>>();

    // pick initial center: passed args or first restaurant
    _currentMapCenter = (_argLat != null && _argLng != null)
        ? LatLng(_argLat!, _argLng!)
        : LatLng(
            (restaurants[0]['Latitude'] ?? restaurants[0]['latitude']) as double,
            (restaurants[0]['Longitude'] ?? restaurants[0]['longitude']) as double,
          );

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentMapCenter, _currentZoom);

      if (_argLat != null && _argLng != null) {
        final idx = restaurants.indexWhere((r) =>
            (r['Latitude'] ?? r['latitude']) == _argLat &&
            (r['Longitude'] ?? r['longitude']) == _argLng);
        if (idx >= 0) {
          _currentSelectedIndex = idx;
          _pageController.jumpToPage(idx);
        }
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(pos.latitude, pos.longitude);
    _currentMapCenter = _currentLocation!;

    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentMapCenter, _currentZoom);
    });
  }

  void _onPageChanged(int idx) {
    setState(() {
      _currentSelectedIndex = idx;
      final r = restaurants[idx];
      _currentMapCenter = LatLng(
        (r['Latitude'] ?? r['latitude']) as double,
        (r['Longitude'] ?? r['longitude']) as double,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentMapCenter, _currentZoom);
    });
  }

  void _zoomIn() {
    if (_currentZoom < 18) {
      _currentZoom++;
      _mapController.move(_currentMapCenter, _currentZoom);
      setState(() {});
    }
  }

  void _zoomOut() {
    if (_currentZoom > 3) {
      _currentZoom--;
      _mapController.move(_currentMapCenter, _currentZoom);
      setState(() {});
    }
  }

  Future<void> showRouteToRestaurant({
    required LatLng userLocation,
    required LatLng restaurantLocation,
    required String restaurantName,
  }) async {
    const apiKey = '5b3ce3597851110001cf6248e936aca9de34476f81806e463c7ae86d';
    final url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey'
        '&start=${userLocation.longitude},${userLocation.latitude}'
        '&end=${restaurantLocation.longitude},${restaurantLocation.latitude}';

    List<LatLng> routePoints = [userLocation, restaurantLocation];
    double distanceKm = 0;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        routePoints = coords
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        distanceKm = data['features'][0]['properties']['segments'][0]['distance'] / 1000;
      } else {
        distanceKm = Geolocator.distanceBetween(
              userLocation.latitude,
              userLocation.longitude,
              restaurantLocation.latitude,
              restaurantLocation.longitude,
            ) /
            1000;
      }
    } catch (_) {
      distanceKm = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            restaurantLocation.latitude,
            restaurantLocation.longitude,
          ) /
          1000;
    }

    setState(() {
      _routePoints = routePoints;
      _routeDistanceKm = distanceKm;
      _routeStart = userLocation;
      _routeEnd = restaurantLocation;
      _currentMapCenter = restaurantLocation;
      _currentZoom = 14;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Route to $restaurantName: ${distanceKm.toStringAsFixed(2)} km')),
    );
  }

  Future<void> insertNavigationHistory(Map<String, dynamic> entry) async {
    // TODO: Implement database insertion logic here
    print('Saving navigation history: $entry');
  }

  Future<void> _saveRouteToHistory() async {
    if (_routeDistanceKm == null || _routeEnd == null || _routeStart == null || _routePoints.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final restaurant = restaurants[_currentSelectedIndex];
    final polyline = _routePoints.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();

    final entry = {
      'restaurant_name': restaurant['CompleteStoreName'] ?? '',
      'distance': _routeDistanceKm,
      'timestamp': now,
      'polyline': jsonEncode(polyline),
      'restaurant': jsonEncode(restaurant),
      'start': jsonEncode({'lat': _routeStart!.latitude, 'lng': _routeStart!.longitude}),
      'end': jsonEncode({'lat': _routeEnd!.latitude, 'lng': _routeEnd!.longitude}),
    };

    await DatabaseHelper().insertNavigationHistory(entry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Route saved to history!')),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────────
  // Show a modal bottom sheet with options for Google Maps or Waze
  Future<void> _showNavigationOptions() async {
    if (_routeStart == null || _routeEnd == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.of(context).pop();
                _launchGoogleMaps();
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () {
                Navigator.of(context).pop();
                _launchWaze();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Launch Google Maps with turn-by-turn directions
  Future<void> _launchGoogleMaps() async {
    if (_routeStart == null || _routeEnd == null) return;

    final startLat = _routeStart!.latitude.toString();
    final startLng = _routeStart!.longitude.toString();
    final endLat   = _routeEnd!.latitude.toString();
    final endLng   = _routeEnd!.longitude.toString();

    final googleUri = Uri(
      scheme: 'https',
      host: 'www.google.com',
      path: 'maps/dir/',
      queryParameters: {
        'api': '1',
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'travelmode': 'driving',
      },
    );

    if (!await launchUrl(googleUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Maps directions.')),
      );
    }
  }

  // Launch Waze with turn-by-turn navigation
  Future<void> _launchWaze() async {
    if (_routeEnd == null) return;

    final lat = _routeEnd!.latitude.toString();
    final lng = _routeEnd!.longitude.toString();
    final wazeUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

    if (!await launchUrl(wazeUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Waze.')),
      );
    }
  }
  // ──────────────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => setState(() => _isSatelliteView = !_isSatelliteView),
          ),
        ],
      ),
      body: restaurants.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentMapCenter,
                    initialZoom: _currentZoom,
                    minZoom: 3,
                    maxZoom: 18,
                    onTap: null,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatelliteView
                          ? 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'
                          : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.yumme_demo.app',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: _routePoints, color: Colors.blue, strokeWidth: 4),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Active restaurant marker (always at currentMapCenter)
                        Marker(
                          point: _currentMapCenter,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            size: 50,
                            color: Colors.red,
                          ),
                        ),
                        // User’s current location
                        if (_currentLocation != null)
                          Marker(
                            point: _currentLocation!,
                            width: 30,
                            height: 30,
                            child: const Icon(
                              Icons.my_location,
                              size: 30,
                              color: Colors.blue,
                            ),
                          ),
                        // Route start (green) & end (red), if a route exists
                        if (_routeStart != null)
                          Marker(
                            point: _routeStart!,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 32),
                          ),
                        if (_routeEnd != null)
                          Marker(
                            point: _routeEnd!,
                            width: 36,
                            height: 36,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                          ),
                      ],
                    ),
                  ],
                ),

                // ──────────────────────────────────────────────────────────────────────────
                // Distance banner + Save & “Go” buttons (only if a route exists)
                if (_routeDistanceKm != null && _routeEnd != null)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Distance banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Distance: ${_routeDistanceKm!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Save Route button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save Route'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _saveRouteToHistory,
                          ),
                          const SizedBox(height: 8),

                          // ───────────── NEW “Go” BUTTON ─────────────
                          ElevatedButton.icon(
                            icon: const Icon(Icons.navigation),
                            label: const Text('Go'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _showNavigationOptions,
                          ),
                          const SizedBox(height: 8),
                          // ────────────────────────────────────────────────
                        ],
                      ),
                    ),
                  ),
                // ──────────────────────────────────────────────────────────────────────────

                // Zoom + Locate FABs (top-right corner)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoomIn',
                        mini: true,
                        onPressed: _zoomIn,
                        child: const Icon(Icons.zoom_in),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoomOut',
                        mini: true,
                        onPressed: _zoomOut,
                        child: const Icon(Icons.zoom_out),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'locate',
                        mini: true,
                        onPressed: _getCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                ),
              ],
            ),

      bottomSheet: restaurants.isEmpty
          ? const SizedBox.shrink()
          : SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                itemCount: restaurants.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (ctx, i) {
                  final r = restaurants[i];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => RestaurantDetailsSheet(
                          restaurant: r,
                          onGetDirections: (LatLng userLoc, LatLng restLoc, String name) {
                            Navigator.of(context).pop(); // Close the sheet
                            showRouteToRestaurant(
                              userLocation: userLoc,
                              restaurantLocation: restLoc,
                              restaurantName: name,
                            );
                          },
                        ),
                      ),
                      child: RestaurantCard(
                        id: r['CompleteStoreName'] as String,
                        name: r['CompleteStoreName'] as String,
                        cuisine: r['FoodType'] as String,
                        dietary: r['Dietary'] as String,
                        rating: (r['AverageRating'] as num).toDouble(),
                        price: r['price'] as String,
                        address: r['address'] as String,
                        operationHours: r['OperationHours'] as String,
                        imageUrl: r['osm_tile_url'] as String,
                        isOpen: r['status'] == 1 || r['status'] == true,
                        latitude: (r['Latitude'] ?? r['latitude']) as double,
                        longitude: (r['Longitude'] ?? r['longitude']) as double,
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => RestaurantDetailsSheet(
                            restaurant: r,
                            onGetDirections: (LatLng userLoc, LatLng restLoc, String name) {
                              Navigator.of(context).pop();
                              showRouteToRestaurant(
                                userLocation: userLoc,
                                restaurantLocation: restLoc,
                                restaurantName: name,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
