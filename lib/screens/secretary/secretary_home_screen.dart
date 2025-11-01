import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/screens/secretary/client_list_screen.dart';
import 'package:gym_app/widgets/KioskModeModal.dart';
import 'package:gym_app/widgets/ActivateTotenModeButton.dart';
import 'package:gym_app/screens/secretary/subscription_renewal_screen.dart';

class SecretaryHomeScreen extends StatelessWidget {
  const SecretaryHomeScreen({Key? key}) : super(key: key);

  Future<String> _getUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
      if (userDoc.exists) {
        return "Hola, ${userDoc.data()?['name'] ?? 'Secretaria'}";
      }
    }
    return "Hola, Secretaria";
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
                  onPressed: () => _handleLogout(context),
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
        ),        actions: [
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
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======== Sección "Modo Asistencia" ========
            const Text(
              'Modo Asistencia',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              'Activar Modo Asistencia',
              'assets/workouts/functional.jpg',
              onTap: () {
                // Show the KioskModeModal
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return KioskModeModal(
                      onConfirm: () {
                        Navigator.of(dialogContext).pop();
                        final totenModeButton = ActivateTotenModeButton();
                        totenModeButton.activarModoTotenYDeslogear(context);
                      },
                      onCancel: () => Navigator.of(dialogContext).pop(),
                    );
                  },
                );
              },
              height: 120,
            ),
            const SizedBox(height: 24),

            // ======== Sección "Creación de clientes" ========
            const Text(
              'Creación de clientes',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              'Crear Cliente',
              'assets/memberships/basic.jpg',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientListScreen(),
                  ),
                );
              },
              height: 200,
            ),
            const SizedBox(height: 16),
            // ======== Sección "Renovación de suscripción" ========
            const Text(
              'Renovación de suscripción',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              'Renovar Suscripción',
              'assets/memberships/premium.jpg',              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionRenewalScreen(),
                  ),
                );
              },
              height: 200,
            ),
            const SizedBox(height: 16),
            // // ======== Sección "Historial de asistencia" ========
            // const Text(
            //   'Historial de asistencia',
            //   style: TextStyle(
            //     color: Colors.white54,
            //     fontSize: 14,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            // const SizedBox(height: 16),
            // _buildOptionCard(
            //   'Ver Historial',
            //   'assets/workouts/cardio.jpg',
            //   onTap: () {
            //     // TODO: Navegar a pantalla de historial de asistencias
            //   },
            //   height: 200,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    String title,
    String imageUrl, {
    required VoidCallback onTap,
    double height = 200,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
