import 'package:flutter/material.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:gym_app/services/create_collections.dart';
import 'package:gym_app/widgets/ActivateTotenModeButton.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 Construyendo WelcomeScreen...');

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Negro más oscuro
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // 🔥 IMAGEN CON ERROR HANDLER
            Image.asset(
              'assets/gym_logo.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('❌ Error cargando imagen: $error');
                return const Icon(
                  Icons.fitness_center,
                  size: 150,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'Rutinas de entrenamiento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await createFakeGymData();
              },
              child: const Text('Crear Datos Fake'),
            ),
            const SizedBox(height: 80),
            const Text(
              'BIENVENIDO Al',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'META ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'GYM',
                  style: TextStyle(
                    color: Color(0xFFFF8C42),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'La solución ideal para tus entrenamientos',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            ElevatedButton(
              onPressed: () async {
                await createFakeGymData();
              },
              child: const Text('Crear Datos Fake'),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.gymCode);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Iniciar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
