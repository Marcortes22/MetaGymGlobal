import 'package:flutter/material.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:gym_app/services/create_collections.dart';
import 'package:gym_app/widgets/ActivateTotenModeButton.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Negro más oscuro
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Image.asset('assets/gym_logo.png', height: 150),
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
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.login);
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.memberships);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFFF8C42),
                          width: 2,
                        ),
                        foregroundColor: Color(0xFFFF8C42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Ver Membresías',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // const Positioned(
                  //   top: 20,
                  //   right: 20,
                  //   child: ActivateTotenModeButton(),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
