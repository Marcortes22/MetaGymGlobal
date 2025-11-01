import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_app/routes/AppRoutes.dart';

class DesactivateTotenModeButton extends StatefulWidget {
  const DesactivateTotenModeButton({super.key});

  @override
  State<DesactivateTotenModeButton> createState() =>
      _DesactivateTotenModeButtonState();
}

class _DesactivateTotenModeButtonState
    extends State<DesactivateTotenModeButton> {
  bool _isLongPressing = false;
  final int _requiredPressDuration = 3; // seconds required for long press
  int _currentPressDuration = 0;

  Future<void> _desactivarModoToten(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear the totem mode setting
    await prefs.setBool('modo_toten', false);

    // For extra safety, also force logout
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Modo Asistencia desactivado"),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate to login screen
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  void _startLongPress() {
    setState(() {
      _isLongPressing = true;
      _currentPressDuration = 0;
    });

    // Start the timer to track long press duration
    Future.doWhile(() async {
      if (!_isLongPressing) return false;

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        _currentPressDuration++;
      });

      if (_currentPressDuration >= _requiredPressDuration) {
        _desactivarModoToten(context);
        return false;
      }

      return _isLongPressing;
    });
  }

  void _endLongPress() {
    setState(() {
      _isLongPressing = false;
      _currentPressDuration = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startLongPress(),
      onLongPressEnd: (_) => _endLongPress(),
      onLongPressCancel: () => _endLongPress(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.settings, color: Colors.grey, size: 28),
          if (_isLongPressing)
            CircularProgressIndicator(
              value: _currentPressDuration / _requiredPressDuration,
              color: Colors.orange,
              strokeWidth: 2,
            ),
        ],
      ),
    );
  }
}
