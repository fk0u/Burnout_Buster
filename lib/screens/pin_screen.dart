import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';

enum PinMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback?
      onSuccess; // Called on successful verify or setup completion

  const PinScreen({super.key, required this.mode, this.onSuccess});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = ''; // Only for setup
  bool _isConfirming = false; // Only for setup
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _message = widget.mode == PinMode.setup
        ? 'Buat PIN Baru (4 Digit)'
        : 'Masukkan PIN Lo';
  }

  void _onKeyPress(String key) {
    if (_pin.length < 4) {
      setState(() {
        _isError = false;
        _pin += key;
      });
      if (_pin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    if (widget.mode == PinMode.verify) {
      // Verify Mode
      final isValid = await AuthService.verifyPin(_pin);
      if (isValid) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          // Default nav if no callback?
        }
      } else {
        setState(() {
          _isError = true;
          _message = 'PIN Salah! Coba lagi.';
          _pin = '';
        });
      }
    } else {
      // Setup Mode
      if (!_isConfirming) {
        // First entry done, ask to confirm
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _isConfirming = true;
          _message = 'Konfirmasi PIN Lo';
        });
      } else {
        // Confirmation entry done
        if (_pin == _confirmPin) {
          await AuthService.setPin(_pin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN Berhasil Disimpan! 🔒')),
            );
            if (widget.onSuccess != null) widget.onSuccess!();
          }
        } else {
          // Mismatch
          setState(() {
            _isError = true;
            _message = 'PIN Gak Sama! Ulangi lagi.';
            _pin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFF10B981))
                .animate(target: _isError ? 1 : 0)
                .shake(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              _message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isError ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            // DOTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isFilled ? const Color(0xFF10B981) : Colors.grey[700],
                    border: isFilled
                        ? null
                        : Border.all(color: Colors.grey, width: 2),
                  ),
                ).animate(target: isFilled ? 1 : 0).scale(duration: 200.ms);
              }),
            ),
            const SizedBox(height: 48),
            // KEYPAD
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9)
                      return const SizedBox.shrink(); // Empty bottom-left
                    if (index == 11) {
                      // Delete button
                      return _buildKeyBtn(
                        child: const Icon(Icons.backspace_outlined,
                            color: Colors.white),
                        onTap: _onDelete,
                      );
                    }
                    final val = index == 10 ? '0' : '${index + 1}';

                    return _buildKeyBtn(
                      child: Text(
                        val,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () => _onKeyPress(val),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyBtn({required Widget child, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: child,
        ),
      ),
    );
  }
}
