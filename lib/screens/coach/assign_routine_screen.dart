// lib/screens/coach/assign_routine_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/services/user_service.dart';
import 'package:gym_app/models/user.dart' as app_user;

class AssignRoutineScreen extends StatelessWidget {
  const AssignRoutineScreen({Key? key}) : super(key: key);

  Future<String> _getUserName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        return "Hola, ${userDoc.data()?['name'] ?? 'Coach'}";
      }
    }
    return "Hola, Coach";
  }

  void _showAssignModal(BuildContext context, app_user.User client) {
    final fullName = "${client.name} ${client.surname1} ${client.surname2}";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Asignar Rutina a $fullName',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Aquí irá el formulario para asignar la rutina.',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Por ejemplo:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('• Seleccionar ejercicios', style: TextStyle(color: Colors.white70)),
            Text('• Definir series y repeticiones', style: TextStyle(color: Colors.white70)),
            Text('• Fecha de inicio', style: TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFFFF8C42)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
            ),
            onPressed: () {
              // TODO: Guardar rutina en Firestore cuando esté listo
              Navigator.pop(context);
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

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
                  onPressed: () => Navigator.pop(context),
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
            icon: const Icon(Icons.notifications_none, color: Color(0xFFFF8C42)),
            onPressed: () {
              // TODO: acción para notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFFFF8C42)),
            onPressed: () {
              // TODO: acción para perfil
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clientes',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<app_user.User>>(
                future: userService.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text(
                        'Error al cargar clientes.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  // Filtrar solo aquellos usuarios cuyo rol contenga "cli"
                  final clients = snapshot.data!
                      .where((u) => u.roles.any((r) => r['id'] == 'cli'))
                      .toList();

                  if (clients.isEmpty) {
                    return const Center(
                      child: Text(
                        'No se encontraron clientes.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      final fullName =
                          "${client.name} ${client.surname1} ${client.surname2}";
                      final heightStr = client.height > 0
                          ? '${client.height} cm'
                          : '—';
                      final weightStr = client.weight > 0
                          ? '${client.weight} kg'
                          : '—';

                      return Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              // Información básica del cliente
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Altura: $heightStr   Peso: $weightStr',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón para asignar rutina
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () =>
                                    _showAssignModal(context, client),
                                child: const Text('Asignar Rutina'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
