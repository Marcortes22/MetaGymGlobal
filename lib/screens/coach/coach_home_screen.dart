// lib/screens/coach/coach_home_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa la nueva pantalla:
import 'package:gym_app/screens/coach/assign_routine_screen.dart';
import 'package:gym_app/routes/AppRoutes.dart';
import 'package:gym_app/screens/coach/assign_workout_screen.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({Key? key}) : super(key: key);

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        return "Hola, ${userData.data()?['name'] ?? 'Coach'}";
      }
    }
    return "Hola, Coach";
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FutureBuilder<String>(
          future: _getUserName(),
          builder: (context, snapshot) {
            return Row(
              children: [
                GestureDetector(
                  onTap: () => _handleLogout(context),
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
                ),
                const SizedBox(width: 8),
                Text(
                  snapshot.data ?? 'Cargando...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFFFF8C42)),
            onPressed: () {
              Navigator.pushNamed(context, '/user-profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ejercicios',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                'Crear\nEjercicios',
                'assets/memberships/basic.jpg',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.exercises);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Rutinas',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Aquí navegamos a AssignRoutineScreen con Navigator.push
              _buildOptionCard(
                'Crear Rutina',
                'assets/workouts/functional.jpg',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.workouts);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Rutinas',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                'Asignar Rutinas',
                'assets/memberships/medium.jpg',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.assignWorkouts);
                },
                height: 240,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      String title,
      String imageUrl, {
        required VoidCallback onTap,
        double height = 180,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 4,
                    color: Colors.black45,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
