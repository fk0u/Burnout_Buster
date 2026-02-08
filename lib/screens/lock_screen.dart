import 'package:flutter/material.dart';
import 'pin_screen.dart';
import '../main.dart'; // For MainScaffold

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PinScreen(
      mode: PinMode.verify,
      onSuccess: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      },
    );
  }
}
