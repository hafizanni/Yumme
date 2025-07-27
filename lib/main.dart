import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yumme/profile/theme_provider.dart';
import 'package:yumme/authentication/login_screen.dart';
import 'package:yumme/authentication/signup_screen.dart';
import 'package:yumme/greeting/GreetingPage.dart';
import 'package:yumme/profile/profile_screen.dart';
import 'package:yumme/screens/RestaurantListScreen.dart';
import 'package:yumme/widgets/customized_button.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:yumme/screens/yummebot_screen.dart';
import 'package:yumme/map/mapScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Dining Assistant',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      initialRoute: '/greeting',
      routes: {
        '/greeting': (context) => GreetingPage(),
        '/onboarding1': (context) => const OnboardingPage1(),
        '/onboarding2': (context) => const OnboardingPage2(),
        '/onboarding3': (context) => const OnboardingPage3(),
        '/auth': (context) => const AuthenticationPage(),
        '/home': (context) => const HomePage(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final String? username;
  final String? email;

  const HomePage({super.key, this.username, this.email});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const RestaurantListScreen(),
      const YummebotScreen(),
      const MapScreen(),
      ProfileScreen(
        username: widget.username ?? 'User',
        email: widget.email ?? 'user@example.com',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: "Yummebot",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: 'Discover Nearby Dining Spots',
      description:
          'Find the best restaurants near you with a quick search. Your next meal is just a tap away!',
      icon: AnimatedEmoji(
        AnimatedEmojis.globeShowingAmericas,
        size: 65,
      ),
      onNext: () => Navigator.pushReplacementNamed(context, '/onboarding2'),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: 'Personalized Restaurant Recommendations',
      description:
          'Get smart dining suggestions based on your preferences, location, and past experiences.',
      icon: AnimatedEmoji(
        AnimatedEmojis.thinkingFace,
        size: 65,
      ),
      onNext: () => Navigator.pushReplacementNamed(context, '/onboarding3'),
    );
  }
}

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingTemplate(
      title: 'Share and Explore Food Experiences',
      description:
          'Join a community of food lovers. Share your meals, explore others’ experiences, and find new favorites.',
      icon: AnimatedEmoji(
        AnimatedEmojis.cameraFlash,
        size: 65,
      ),
      onNext: () => Navigator.pushReplacementNamed(context, '/auth'),
    );
  }
}

class AuthenticationPage extends StatelessWidget {
  const AuthenticationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 130,
                width: 260,
                child: Image(
                  image: AssetImage("assets/images/yumme.png"),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
              CustomizedButton(
                buttonText: "Login",
                buttonColor: const Color(0xFF6C63FF),
                textColor: Colors.white,
                icon: Icons.login,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              ),
              CustomizedButton(
                buttonText: "Sign Up",
                buttonColor: Colors.white,
                textColor: const Color(0xFF6C63FF),
                icon: Icons.person_add_alt_1,
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()));
                },
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(10.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingTemplate extends StatelessWidget {
  final String title;
  final String description;
  final Widget icon;
  final VoidCallback onNext;

  const OnboardingTemplate({
    required this.title,
    required this.description,
    required this.icon,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child: icon,
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}