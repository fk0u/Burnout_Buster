import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/ai_service.dart';
import 'services/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/encryption_service.dart';
import 'services/energy_service.dart'; // New Service
import 'screens/onboarding_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/mood_tracker_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/touch_grass_screen.dart';
import 'screens/diary_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/dashboard_screen.dart'; // New Screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive with Encryption
  await EncryptionService.initSecureHive();

  // Check if PIN is set
  bool pinSet = await AuthService.isPinSet();

  runApp(BurnoutBusterApp(initialAuth: pinSet));
}

class BurnoutBusterApp extends StatelessWidget {
  final bool initialAuth;
  const BurnoutBusterApp({super.key, required this.initialAuth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => EnergyService()), // Register EnergyService
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Burnout Buster',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            // Decide start screen
            home: initialAuth ? const LockScreen() : const OnboardingWrapper(),
            routes: {
              '/onboarding': (context) => const OnboardingScreen(),
              '/chat': (context) => const MainScaffold(),
            },
          );
        },
      ),
    );
  }
}

// Wrapper to handle shared prefs check if no auth
class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  @override
  void initState() {
    super.initState();
    _checkPrefs();
  }

  void _checkPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingComplete =
        prefs.getBool('onboardingComplete') ?? false;
    if (mounted) {
      if (onboardingComplete) {
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  void _onNavigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigate: _onNavigate), // 0: Home
      const ChatScreen(), // 1: Jedo
      const MoodTrackerScreen(), // 2: Mood
      const DiaryScreen(), // 3: Diary
      const TouchGrassScreen(), // 4: Healing
      const SettingsScreen(), // 5: Hidden via Tab (accessed from Dashboard)
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex > 4
            ? 0
            : _selectedIndex, // Reset if > 4 (Settings) or show Home
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Jedo',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood),
            selectedIcon: Icon(Icons.mood_bad),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Diary',
          ),
          NavigationDestination(
            icon: Icon(Icons.nature),
            selectedIcon: Icon(Icons.nature_people),
            label: 'Healing',
          ),
        ],
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF10B981).withOpacity(0.2),
      ),
    );
  }
}
