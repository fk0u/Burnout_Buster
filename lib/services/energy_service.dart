import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnergyService extends ChangeNotifier {
  double _energyLevel = 100.0;
  DateTime _lastUpdated = DateTime.now();

  double get energyLevel => _energyLevel;

  static const String _keyEnergy = 'energy_level';
  static const String _keyLastUpdated = 'energy_last_updated';

  EnergyService() {
    _loadEnergy();
  }

  Future<void> _loadEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    _energyLevel = prefs.getDouble(_keyEnergy) ?? 100.0;
    final lastup = prefs.getInt(_keyLastUpdated);
    if (lastup != null) {
      _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastup);
    }

    // Calculate passive drain based on time elapsed
    _calculatePassiveDrain();
    notifyListeners();
  }

  void _calculatePassiveDrain() {
    final now = DateTime.now();
    final difference = now.difference(_lastUpdated);
    // Drain 1% every hour (just an example base rate)
    final hoursPassed = difference.inMinutes / 60.0;
    if (hoursPassed > 0) {
      // Simple linear drain: 1.0 per hour
      double drain = hoursPassed * 1.0;
      _energyLevel = (_energyLevel - drain).clamp(0.0, 100.0);
      _saveEnergy();
    }
  }

  Future<void> _saveEnergy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyEnergy, _energyLevel);
    await prefs.setInt(_keyLastUpdated, DateTime.now().millisecondsSinceEpoch);
    notifyListeners();
  }

  void drainEnergy(double amount) {
    _energyLevel = (_energyLevel - amount).clamp(0.0, 100.0);
    _saveEnergy();
  }

  void rechargeEnergy(double amount) {
    _energyLevel = (_energyLevel + amount).clamp(0.0, 100.0);
    _saveEnergy();
  }

  // Set specific level (debug or reset)
  void setEnergy(double amount) {
    _energyLevel = amount.clamp(0.0, 100.0);
    _saveEnergy();
  }
}
