import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/energy_service.dart';

class EnergyBatteryWidget extends StatelessWidget {
  const EnergyBatteryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnergyService>(
      builder: (context, energyService, child) {
        final level = energyService.energyLevel;
        Color color;
        if (level > 60) {
          color = const Color(0xFF10B981); // Green
        } else if (level > 30) {
          color = const Color(0xFFF59E0B); // Orange
        } else {
          color = const Color(0xFFEF4444); // Red
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Baterai Sosial',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${level.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ).animate(key: ValueKey(level)).scale(
                        duration: 300.ms,
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!, width: 2),
                ),
                child: Stack(
                  children: [
                    // Fill animation
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuart,
                      widthFactor: level / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.7),
                              color,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                    // Thunderbolt Icon if low?
                    if (level < 20)
                      const Positioned.fill(
                              child: Icon(Icons.bolt,
                                  size: 16, color: Colors.yellowAccent))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(duration: 500.ms),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusMessage(level),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fade().slideX(),
            ],
          ),
        );
      },
    );
  }

  String _getStatusMessage(double level) {
    if (level > 80) return 'Full power! Gasabar mau ngapain? ⚡';
    if (level > 50) return 'Masih aman. Jangan lupa napas. 😌';
    if (level > 20) return 'Mulai lowbat nih. Kurangin medsos bentar. ⚠️';
    return 'DANGER ZONE! Touch Grass SEKARANG! 🚨';
  }
}
