import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/digital_wellbeing_service.dart';
import 'pin_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _usageGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final granted = await DigitalWellbeingService.hasPermission();
    if (mounted) {
      setState(() {
        _usageGranted = granted;
      });
    }
  }

  Future<void> _nextStep() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PinScreen(
            mode: PinMode.setup,
            onSuccess: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboardingComplete', true);
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    '/chat', (Route<dynamic> route) => false);
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Izin Dulu Biar Makin Akrab 🤝',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fade().slideY(begin: -0.2, end: 0),
              const SizedBox(height: 16),
              const Text(
                'Biar fitur Burnout Buster maksimal, kita butuh akses dikit nih bro.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ).animate().fade(delay: 200.ms),
              const SizedBox(height: 40),
              _buildPermissionItem(
                title: 'Akses Penggunaan App (Digital Wellbeing)',
                description:
                    'Buat ngasih tau lo aplikasi apa yang bikin burnout. Tenang, data aman di hape lo doang.',
                icon: Icons.access_time_filled,
                isGranted: _usageGranted,
                onTap: () async {
                  if (!_usageGranted) {
                    await DigitalWellbeingService.requestPermission();
                    // Permission check happens in didChangeAppLifecycleState
                  }
                },
              ).animate().fade(delay: 400.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              /*
              _buildPermissionItem(
                title: 'Notifikasi (Biar Gak Lupa)',
                description: 'Buat ngingetin lo napas bentar & check-in mood.',
                icon: Icons.notifications_active,
                isGranted: true, // TODO: Implement Notification check
                onTap: () {},
              ).animate().fade(delay: 600.ms).slideX(begin: -0.1, end: 0),
              */
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _usageGranted
                        ? const Color(0xFF10B981)
                        : Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _usageGranted ? 'Lanjut, Gas! 🚀' : 'Nanti Aja Deh (Skip)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fade(delay: 800.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(16),
          border: isGranted
              ? Border.all(color: const Color(0xFF10B981), width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : Colors.grey[800],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGranted ? Icons.check : icon,
                color: isGranted ? const Color(0xFF10B981) : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (!isGranted)
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
