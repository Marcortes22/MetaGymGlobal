import 'package:flutter/material.dart';
import 'package:gym_app/routes/AppRoutes.dart';

class NoRoleScreen extends StatelessWidget {
  const NoRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 30),
              const Text(
                'Acceso Restringido',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD1442F),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta no tiene un rol asignado en el sistema. Por favor contacta con el administrador o vuelve a iniciar sesión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD1442F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                    side: const BorderSide(color: Color(0xFFD1442F)),
                  ),
                ),
                child: const Text(
                  'Volver al inicio de sesión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
