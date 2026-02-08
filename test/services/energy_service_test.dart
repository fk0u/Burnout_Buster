import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:burnout_buster/services/energy_service.dart';

void main() {
  group('EnergyService Tests', () {
    late EnergyService service;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({}); // Empty prefs
      // We need to await the service initialization?
      // The constructor calls _loadEnergy which is async but not awaited.
      // However, since we mock values before, hopefully it picks it up.
      // To be safe, we might need a way to wait for load, but for now let's try.
      service = EnergyService();
      // Wait a bit for the future in constructor to complete
      await Future.delayed(Duration(milliseconds: 50));
    });

    test('Initial energy should be 100', () {
      expect(service.energyLevel, 100.0);
    });

    test('drainEnergy should decrease level', () {
      service.drainEnergy(10.0);
      expect(service.energyLevel, 90.0);
    });

    test('rechargeEnergy should increase level', () {
      service.drainEnergy(20.0); // 80
      service.rechargeEnergy(10.0);
      expect(service.energyLevel, 90.0);
    });

    test('Energy should be clamped between 0 and 100', () {
      service.drainEnergy(200.0);
      expect(service.energyLevel, 0.0);

      service.rechargeEnergy(200.0);
      expect(service.energyLevel, 100.0);
    });
  });
}
