import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/gestures.dart';

class YummebotScreen extends StatefulWidget {
  const YummebotScreen({super.key});

  @override
  State<YummebotScreen> createState() => _YummebotScreenState();
}

class _YummebotScreenState extends State<YummebotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isServerOnline = true;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'text': '👋 Hi! I can help you find restaurants. Try asking "Find halal restaurants near me" or "Find Italian restaurants".',
      'isUser': false
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _isLoading = true;
    });

    String response;
    Position? position;

    // If user asks for "near me", get location
    if (text.toLowerCase().contains('near me')) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _messages.add({'text': 'Location services are disabled.', 'isUser': false});
            _isLoading = false;
          });
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() {
              _messages.add({'text': 'Location permission denied.', 'isUser': false});
              _isLoading = false;
            });
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          setState(() {
            _messages.add({'text': 'Location permissions are permanently denied.', 'isUser': false});
            _isLoading = false;
          });
          return;
        }

        position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        setState(() {
          _messages.add({'text': 'Failed to get location: $e', 'isUser': false});
          _isLoading = false;
        });
        return;
      }
    }

    // Pass location to ChatGPT if available
    response = await _getBotResponse(
      position != null
        ? '$text\nUser location: lat=${position.latitude}, lng=${position.longitude}'
        : text
    );

    // Extract restaurant names from the response
    final restaurants = extractRestaurantsFromResponse(response);

    setState(() {
      if (restaurants.isNotEmpty) {
        _messages.add({'isUser': false, 'restaurants': restaurants});
      } else {
        _messages.add({'text': response, 'isUser': false});
      }
      _isLoading = false;
    });
  }

  Future<String> _getBotResponse(String text) async {
    return await callChatGPT(text);
  }

  Future<String> callChatGPT(String userMessage) async {
    const apiKey = "xxxx"; // Replace with your key
    const apiUrl = "https://api.openai.com/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content": "You are a helpful restaurant assistant in Malaysia. When the user asks for restaurants, reply with a JSON array. Each item should have: name, address, url, and rating (1-5). Example: [{\"name\": \"ABC Cafe\", \"address\": \"123 Street\", \"url\": \"https://abc.com\", \"rating\": 4.5}]."
            },
            {"role": "user", "content": userMessage},
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['choices'][0]['message']['content'].toString().trim();
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'Failed to connect to ChatGPT: $e';
    }
  }

  /// Parses ChatGPT response to extract restaurants from JSON array
  List<Map<String, dynamic>> extractRestaurantsFromResponse(String text) {
    try {
      final data = jsonDecode(text);
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/yumme.png',
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text('Yummebot', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_isServerOnline ? Icons.cloud_done : Icons.cloud_off),
            onPressed: () {},
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListView.builder(
                        reverse: false,
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, index) {
                          final message = _messages[index];
                          if (message.containsKey('restaurants')) {
                            // Show clickable restaurant list
                            return RestaurantListWidget(
                              restaurants: List<Map<String, dynamic>>.from(message['restaurants']),
                              onTap: (restaurant) {
                                Navigator.pushNamed(context, '/map', arguments: restaurant);
                              },
                            );
                          } else {
                            // Show modern chat bubble
                            return ChatBubble(
                              text: message['text'] ?? '',
                              isUser: message['isUser'] ?? false,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: LinearProgressIndicator(
                    color: Color(0xFF6C63FF),
                    backgroundColor: Colors.white24,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          enabled: _isServerOnline,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: _isServerOnline
                                ? 'Ask Yummebot anything...'
                                : 'Service unavailable',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          ),
                          onSubmitted: (text) {
                            _sendMessage(text);
                            _controller.clear();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _sendMessage(_controller.text);
                        _controller.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF0DAE96)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestaurantListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final void Function(Map<String, dynamic> restaurant) onTap;

  const RestaurantListWidget({
    Key? key,
    required this.restaurants,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: restaurants.asMap().entries.map((entry) {
        final i = entry.key;
        final restaurant = entry.value;
        return GestureDetector(
          onTap: () => onTap(restaurant),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        restaurant['name'] ?? '',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (restaurant['address'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 40),
                    child: Text(
                      restaurant['address'],
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                if (restaurant['url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 40),
                    child: GestureDetector(
                      onTap: () async {
                        final url = restaurant['url'];
                        if (await canLaunch(url)) {
                          await launch(url);
                        }
                      },
                      child: Text(
                        restaurant['url'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                if (restaurant['rating'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 40),
                    child: Row(
                      children: List.generate(5, (star) {
                        final rating = (restaurant['rating'] as num).toDouble();
                        return Icon(
                          star < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser
        ? const Color(0xFF6C63FF).withOpacity(0.9)
        : Colors.white.withOpacity(0.92);
    final textColor = isUser ? Colors.white : Colors.black87;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final avatar = isUser
        ? const CircleAvatar(
            backgroundColor: Color(0xFF6C63FF),
            child: Icon(Icons.person, color: Colors.white),
            radius: 18,
          )
        : const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.android, color: Color(0xFF6C63FF)),
            radius: 18,
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: align,
        children: [
          if (!isUser) avatar,
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildRichText(context, text, textColor),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) avatar,
        ],
      ),
    );
  }

  // Helper to build RichText with clickable links
  Widget _buildRichText(BuildContext context, String text, Color textColor) {
    final urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final matches = urlRegExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: TextStyle(fontSize: 16, color: textColor));
    }

    final spans = <TextSpan>[];
    int last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: TextStyle(fontSize: 16, color: textColor),
        ));
      }
      final url = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (await canLaunch(url)) {
              await launch(url);
            }
          },
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: TextStyle(fontSize: 16, color: textColor),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF0DAE96)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
