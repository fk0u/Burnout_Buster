import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/energy_service.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int? _selectedMood;
  late Box _moodBox;
  List<FlSpot> _chartData = [];

  final List<Map<String, dynamic>> _moods = [
    {'score': 1, 'emoji': '😠', 'label': 'Marah'},
    {'score': 2, 'emoji': '😞', 'label': 'Sedih'},
    {'score': 3, 'emoji': '😐', 'label': 'B aja'},
    {'score': 4, 'emoji': '🙂', 'label': 'Happy'},
    {'score': 5, 'emoji': '🤩', 'label': 'Excited'},
  ];

  @override
  void initState() {
    super.initState();
    _moodBox = Hive.box('moodHistory');
    _loadMoodData();
  }

  void _loadMoodData() {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);

    // Check if recorded today
    if (_moodBox.containsKey(todayKey)) {
      setState(() {
        _selectedMood = _moodBox.get(todayKey);
      });
    }

    // Generate Chart Data (Last 7 days)
    List<FlSpot> spots = [];
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final k = DateFormat('yyyy-MM-dd').format(d);
      if (_moodBox.containsKey(k)) {
        spots.add(
            FlSpot((6 - i).toDouble(), (_moodBox.get(k) as int).toDouble()));
      } else {
        spots.add(FlSpot((6 - i).toDouble(), 0)); // 0 means no data
      }
    }
    setState(() {
      _chartData = spots;
    });
  }

  void _saveMood(int score) {
    if (_selectedMood == score) return; // Prevent spam

    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _moodBox.put(todayKey, score);

    // Recharge Social Battery!
    if (mounted) {
      context.read<EnergyService>().rechargeEnergy(10.0);
    }

    setState(() {
      _selectedMood = score;
      _loadMoodData(); // Refresh chart
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Mood saved: ${_moods.firstWhere((m) => m['score'] == score)['label']}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gimana Perasaan Lo Hari Ini?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((m) {
                final isSelected = _selectedMood == m['score'];
                return GestureDetector(
                  onTap: () => _saveMood(m['score']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : null,
                    ),
                    child: Text(
                      m['emoji'],
                      style: const TextStyle(fontSize: 32),
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 200.ms,
                            curve: Curves.elasticOut)
                        .shake(hz: 4, curve: Curves.easeInOutCubic),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            const Text(
              'Trend Minggu Ini',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1.70,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          // value 0 = 6 days ago, value 6 = today
                          final date =
                              now.subtract(Duration(days: 6 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(DateFormat('E').format(date),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  maxY: 6,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutQuart)
                .fade(duration: 600.ms),
          ],
        ),
      ),
    );
  }
}
