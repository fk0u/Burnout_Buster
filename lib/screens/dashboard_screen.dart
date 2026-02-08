import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/energy_battery_widget.dart';
import '../widgets/burnout_radar_widget.dart';
import 'zen_mode_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate; // To switch tabs from dashboard

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Burnout Buster V2.0',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => onNavigate(4), // Assume settings is index 4
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Social Battery
            const EnergyBatteryWidget()
                .animate()
                .slideY(begin: -0.2, end: 0, duration: 500.ms),
            const SizedBox(height: 16),

            // 2. Burnout Radar
            const BurnoutRadarWidget()
                .animate()
                .slideY(begin: -0.2, end: 0, duration: 600.ms),
            const SizedBox(height: 24),

            // 3. Greeting / Status
            const Text(
              'Apa kabar mental lo hari ini?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),

            // 3. Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  title: 'Curhat (AI)',
                  icon: Icons.chat_bubble_outline,
                  color: Colors.blueAccent,
                  onTap: () => onNavigate(1), // Chat Tab
                ),
                _buildActionCard(
                  context,
                  title: 'Cek Mood',
                  icon: Icons.mood,
                  color: Colors.orangeAccent,
                  onTap: () => onNavigate(2), // Mood Tab
                ),
                _buildActionCard(
                  context,
                  title: 'Healing Dulu',
                  icon: Icons.nature_people,
                  color: Colors.greenAccent,
                  onTap: () => onNavigate(3), // Healing Tab
                ),
                _buildActionCard(
                  context,
                  title: 'Zen Mode',
                  icon: Icons.self_improvement,
                  color: Colors.purpleAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ZenModeScreen()),
                    );
                  },
                ),
              ],
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B)
                .withOpacity(0.5), // Slightly lighter than background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
