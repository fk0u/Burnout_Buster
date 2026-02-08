import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _botNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _botNameController.text = prefs.getString('jedoName') ?? 'Jedo';
    });
  }

  Future<void> _saveName(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jedoName', val);
  }

  Future<void> _clearHistory() async {
    // Clear Hive Boxes
    await Hive.box('chatHistory').clear();
    await Hive.box('moodHistory').clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('History cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
          title: const Text('Pengaturan'), centerTitle: true, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Customization',
              style: TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _botNameController,
            decoration: InputDecoration(
              labelText: 'Nama Chatbot',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: _saveName,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            activeColor: const Color(0xFF10B981),
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
            secondary: const Icon(Icons.dark_mode),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 48, color: Colors.grey),
          const Text('Data & Privacy',
              style: TextStyle(
                  color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Hapus History Chat & Mood',
                style: TextStyle(color: Colors.redAccent)),
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onTap: _clearHistory,
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            title: const Text(
              'Log Out (Demo)',
              style: TextStyle(color: Colors.grey),
            ),
            leading: const Icon(Icons.logout, color: Colors.grey),
            onTap: () {
              // Reset onboarding
              SharedPreferences.getInstance().then(
                (p) => p.setBool('onboardingComplete', false),
              );
              Navigator.of(context).pushReplacementNamed('/');
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
