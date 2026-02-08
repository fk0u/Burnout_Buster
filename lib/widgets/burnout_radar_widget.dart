import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/burnout_prediction_service.dart';

class BurnoutRadarWidget extends StatefulWidget {
  const BurnoutRadarWidget({super.key});

  @override
  State<BurnoutRadarWidget> createState() => _BurnoutRadarWidgetState();
}

class _BurnoutRadarWidgetState extends State<BurnoutRadarWidget> {
  @override
  void initState() {
    super.initState();
    // Auto-scan on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BurnoutPredictionService>().analyzeBurnout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BurnoutPredictionService>(
      builder: (context, service, child) {
        final risk = service.risk;
        Color color;
        IconData icon;
        String status;

        switch (risk) {
          case BurnoutRisk.low:
            color = const Color(0xFF10B981);
            icon = Icons.check_circle_outline;
            status = "Low Risk";
            break;
          case BurnoutRisk.medium:
            color = const Color(0xFFF59E0B);
            icon = Icons.warning_amber_rounded;
            status = "Medium Risk";
            break;
          case BurnoutRisk.high:
            color = const Color(0xFFEF4444);
            icon = Icons.error_outline;
            status = "High Risk";
            break;
          case BurnoutRisk.critical:
            color = const Color(0xFFDC2626);
            icon = Icons.report_problem;
            status = "CRITICAL";
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Text(
                    "Burnout Radar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(
                          key: ValueKey(risk),
                          onPlay: (c) => c.repeat(reverse: true))
                      .fade(
                          duration: 1000.ms,
                          begin: 0.5,
                          end: 1.0), // Breathing effect
                ],
              ),
              const SizedBox(height: 12),
              if (service.isLoading)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else
                Text(
                  service.advice,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ).animate(key: ValueKey(service.advice)).fade(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.read<BurnoutPredictionService>().analyzeBurnout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueAccent,
                    side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                  ),
                  child: const Text("Scan Now"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
