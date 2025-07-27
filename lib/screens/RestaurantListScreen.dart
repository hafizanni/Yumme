import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yumme/authentication/database/database.dart';
import 'package:yumme/widgets/RestaurantCard.dart';
import 'package:yumme/services/spinwheelpage.dart';
import 'package:yumme/screens/yummebot_screen.dart'; // or adjust the path as needed

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({Key? key}) : super(key: key);

  @override
  _RestaurantListScreenState createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final int userId = 1;
  List<Map<String, dynamic>> restaurants = [];
  List<Map<String, dynamic>> filteredRestaurants = [];
  List<Map<String, dynamic>> searchHistory = [];

  final Map<String, List<String>> categoryMap = {
    'Dietary': ['Halal (322)', 'Non-Halal (24)', 'Vegetarian (9)'],
    'Cuisine': [
      'Malaysian (66)', 'Asian (43)', 'Chinese (24)', 'Middle Eastern (19)', 'Western (12)',
      'Seafood (6)', 'Thai (3)', 'Japanese (2)', 'International (2)', 'Italian (1)',
      'European (1)', 'Korean (1)', 'American (1)', 'Indian (27)'
    ],
    'Cafe/Dessert': ['Desserts (7)', 'Pasta (4)', 'Cakes (4)', 'Coffee (3)', 'Bread (2)', 'Beverages (1)'],
    'Breakfast/Lunch/Dinner': [
      'Roti Canai (19)', 'Fried Rice (16)', 'Ayam Penyet (6)', 'Noodles (5)', 'Briyani (5)',
      'Nasi Lemak (4)', 'Rice Dishes (3)', 'Chicken Rice (2)', 'Tom Yum (3)', 'Sandwiches (2)',
      'Nasi Kandar (1)', 'Nasi Kukus (1)'
    ],
    'Other': [
      'Chicken (24)', 'Shawarma (5)', 'Soups (7)', 'Pizza (3)', 'Burgers (3)', 'Chicken Chop (3)',
      'Fast Food (1)', 'Porridge (1)', 'Sushi (1)', 'Dumpling (1)', 'Satay (1)', 'Fried Chicken (1)',
      'Snacks (1)', 'Healthy (1)', 'Tea (1)'
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _loadSearchHistory();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) _clearSearch();
    });
  }

  Future<void> _loadRestaurants() async {
    final String jsonString = await rootBundle.loadString('assets/data/top_rated_restaurants_with_osm.json');
    final List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      restaurants = jsonData.cast<Map<String, dynamic>>();
      filteredRestaurants = restaurants;
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await getSearchHistory(userId);
    final seen = <String>{};
    final deduped = history.where((item) => seen.add(item['query'])).toList();
    setState(() {
      searchHistory = deduped;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => filteredRestaurants = restaurants);
  }

  void _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _clearSearch();
      return;
    }
    try {
      await addSearchHistory(query, userId);
      await _loadSearchHistory();
    } catch (e) {}
    _performSearch(query);
  }

  void _performSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredRestaurants = restaurants.where((r) {
        final dietary = r['Dietary']?.toString().toLowerCase() ?? '';
        final foodType = r['FoodType']?.toString().toLowerCase() ?? '';
        final name = r['CompleteStoreName']?.toString().toLowerCase() ?? '';
        return dietary.contains(q) || foodType.contains(q) || name.contains(q);
      }).toList();
    });
  }

  void _showCategoryItems(String category) {
    final items = categoryMap[category]!;
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, idx) {
          final label = items[idx];
          final query = label.split(' (').first;
          return ListTile(
            title: Text(query),
            onTap: () {
              Navigator.pop(context);
              _searchController.text = query;
              _onSearch();
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Restaurant List'),
          backgroundColor: Colors.transparent,
          elevation: 1,
          foregroundColor: Colors.black87,
          automaticallyImplyLeading: false, // <-- Add this line to remove the back arrow
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpinWheelPage()),
                );
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(24),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              if (searchHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: searchHistory.length > 5 ? 5 : searchHistory.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final item = searchHistory[i];
                        return ActionChip(
                          label: Text(item['query']),
                          backgroundColor: Colors.blue[50],
                          onPressed: () {
                            _searchController.text = item['query'];
                            _onSearch();
                          },
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: filteredRestaurants.length == restaurants.length,
                      onSelected: (_) => _clearSearch(),
                      selectedColor: Colors.blue[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    for (var category in categoryMap.keys) ...[
                      ChoiceChip(
                        label: Row(
                          children: [
                            Icon(
                              category == 'Dietary'
                                  ? Icons.restaurant_menu
                                  : category == 'Cuisine'
                                      ? Icons.ramen_dining
                                      : category == 'Cafe/Dessert'
                                          ? Icons.coffee
                                          : category == 'Breakfast/Lunch/Dinner'
                                              ? Icons.breakfast_dining
                                              : Icons.fastfood,
                              size: 18,
                              color: Colors.blueGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(category),
                          ],
                        ),
                        selected: false,
                        onSelected: (_) => _showCategoryItems(category),
                        selectedColor: Colors.blue[100],
                        backgroundColor: Colors.grey[200],
                        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filteredRestaurants.isEmpty
                    ? const Center(child: Text('No restaurants found'))
                    : SizedBox(
                        height: 340, // Adjust height as needed for your card
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredRestaurants.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (ctx, i) {
                            final r = filteredRestaurants[i];
                            return SizedBox(
                              width: 320, // Adjust width as needed for your card
                              child: RestaurantCard(
                                id: r['CompleteStoreName'] ?? '',
                                name: r['CompleteStoreName'] ?? '',
                                cuisine: r['FoodType'] ?? '',
                                dietary: r['Dietary'] ?? '',
                                rating: (r['AverageRating'] as num?)?.toDouble() ?? 0.0,
                                price: r['price'] ?? '',
                                address: r['address'] ?? '',
                                operationHours: r['OperationHours'] ?? '',
                                imageUrl: r['osm_tile_url'] ?? '',
                                isOpen: r['status'] == 1 || r['status'] == true,
                                latitude: (r['Latitude'] as num?)?.toDouble() ?? 0.0,
                                longitude: (r['Longitude'] as num?)?.toDouble() ?? 0.0,
                                onTap: () {
                                  // Navigate or show details
                                },
                              ),
                            );
                          },
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
