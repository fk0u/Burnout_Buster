import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/energy_service.dart';

class ZenModeScreen extends StatefulWidget {
  const ZenModeScreen({super.key});

  @override
  State<ZenModeScreen> createState() => _ZenModeScreenState();
}

class _ZenModeScreenState extends State<ZenModeScreen>
    with WidgetsBindingObserver {
  int _selectedDuration = 20; // Default minutes
  bool _isSessionActive = false;
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _failed = false;
  bool _completed = false;

  // Creature States: 0=Egg, 1=Baby, 2=Adult, 3=Withered
  int _creatureStage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSessionActive && state == AppLifecycleState.paused) {
      // User left the app!
      setState(() {
        _failSession();
      });
    }
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _secondsRemaining = _selectedDuration * 60;
      _creatureStage = 0; // Start as Egg
      _failed = false;
      _completed = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _updateCreatureGrowth();
        } else {
          _completeSession();
        }
      });
    });
  }

  void _updateCreatureGrowth() {
    double progress = 1 - (_secondsRemaining / (_selectedDuration * 60));
    if (progress > 0.5 && _creatureStage == 0) _creatureStage = 1; // Hatch
    if (progress > 0.9 && _creatureStage == 1) _creatureStage = 2; // Adult
  }

  void _failSession() {
    _timer?.cancel();
    _isSessionActive = false;
    _failed = true;
    _creatureStage = 3; // Withered
    // Penalty? Maybe drain battery slightly?
    context.read<EnergyService>().drainEnergy(5.0);
  }

  void _completeSession() {
    _timer?.cancel();
    _isSessionActive = false;
    _completed = true;
    _creatureStage = 2; // Confirmed Adult
    // Reward!
    context.read<EnergyService>().rechargeEnergy(20.0);
  }

  void _stopSession() {
    if (_isSessionActive) {
      // Confirm give up?
      showDialog(
          context: context,
          builder: (c) => AlertDialog(
                title: const Text("Give up?"),
                content: const Text("Your creature will not survive."),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text("Stay")),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        setState(() => _failSession());
                      },
                      child: const Text("Give Up",
                          style: TextStyle(color: Colors.red))),
                ],
              ));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      appBar: AppBar(
        title: const Text("Zen Mode 🧘‍♂️"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _stopSession,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Creature Visualization
            _buildCreature(),
            const SizedBox(height: 40),

            if (_isSessionActive)
              Text(
                _formatTime(_secondsRemaining),
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )
            else if (_failed)
              const Text("Session Failed 💀",
                  style: TextStyle(fontSize: 24, color: Colors.redAccent))
            else if (_completed)
              const Text("Zen Master! 🎉",
                  style: TextStyle(fontSize: 24, color: Colors.greenAccent))
            else
              // Duration Selector
              DropdownButton<int>(
                value: _selectedDuration,
                dropdownColor: const Color(0xFF334155),
                style: const TextStyle(fontSize: 24, color: Colors.white),
                items: [1, 5, 20, 30, 45, 60]
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text("$m min")))
                    .toList(),
                onChanged: (val) => setState(() => _selectedDuration = val!),
              ),

            const SizedBox(height: 40),

            // Action Button
            if (!_isSessionActive && !_completed && !_failed)
              ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Focus"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Colors.purpleAccent,
                ),
              )
            else if (_failed || _completed)
              ElevatedButton(
                onPressed: () => setState(() {
                  _failed = false;
                  _completed = false;
                  _creatureStage = 0;
                }),
                child: const Text("Try Again"),
              ),

            const SizedBox(height: 20),
            if (_isSessionActive)
              const Text("Don't leave the app!",
                  style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreature() {
    IconData icon;
    Color color;
    double scale = 1.0;

    switch (_creatureStage) {
      case 0: // Egg
        icon = Icons.egg;
        color = Colors.white;
        break;
      case 1: // Baby
        icon = Icons.child_care;
        color = Colors.lightBlueAccent;
        scale = 1.2;
        break;
      case 2: // Adult
        icon = Icons.self_improvement;
        color = Colors.purpleAccent;
        scale = 1.5;
        break;
      case 3: // Withered
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        icon = Icons.egg;
        color = Colors.white;
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
      ),
      child: Icon(icon, size: 80 * scale, color: color)
          .animate(
              key: ValueKey(_creatureStage),
              onPlay: (c) => c.repeat(reverse: true))
          .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 2.seconds),
    );
  }

  String _formatTime(int totalSeconds) {
    int min = totalSeconds ~/ 60;
    int sec = totalSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }
}
