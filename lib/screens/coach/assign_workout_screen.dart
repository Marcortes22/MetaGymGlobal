import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_app/models/assigned_workout.dart';
import 'package:gym_app/models/user.dart';
import 'package:gym_app/models/workout.dart';
import 'package:gym_app/services/assigned_workout_service.dart';

class AssignWorkoutScreen extends StatefulWidget {
  const AssignWorkoutScreen({super.key});

  @override
  State<AssignWorkoutScreen> createState() => _AssignWorkoutScreenState();
}

class _AssignWorkoutScreenState extends State<AssignWorkoutScreen> {
  final AssignedWorkoutService _assignedWorkoutService =
      AssignedWorkoutService();

  Future<List<User>> _getClients() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('roles', arrayContains: {'id': 'cli', 'name': 'Cliente'})
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User.fromMap(doc.id, data);
    }).toList();
  }

  Future<List<Workout>> _getWorkouts() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('workouts').get();
    return snapshot.docs
        .map((doc) => Workout.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<AssignedWorkout>> _getAssignedWorkouts(String userId) async {
    return await _assignedWorkoutService.getByUser(userId);
  }

  Future<void> _assignWorkout(
    BuildContext context,
    User user,
    Workout workout,
  ) async {
    try {
      // Verificar si la rutina ya está asignada
      final isAssigned = await _assignedWorkoutService.isWorkoutAssigned(
        user.id,
        workout.id,
      );
      if (isAssigned) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta rutina ya está asignada a este usuario'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final assigned = AssignedWorkout(
        id: '',
        userId: user.id,
        workoutId: workout.id,
        assignedAt: DateTime.now(),
        status: 'assigned',
      );

      final assignedWorkout = await _assignedWorkoutService.assignWorkout(
        assigned,
      );

      if (!mounted) return;
      setState(() {}); // Actualizar la UI
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rutina asignada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar la rutina: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Asignar Rutinas',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFF8C42)),
      ),
      body: FutureBuilder<List<User>>(
        future: _getClients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final clients = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFF8C42).withOpacity(0.2),
                    child: Text(
                      client.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFFF8C42),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '${client.name} ${client.surname1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    client.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFFF8C42),
                    ),
                    onPressed:
                        () => _showWorkoutSelectionDialog(context, client),
                  ),
                  children: [
                    FutureBuilder<List<AssignedWorkout>>(
                      future: _getAssignedWorkouts(client.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final assignedWorkouts = snapshot.data ?? [];

                        if (assignedWorkouts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay rutinas asignadas',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return FutureBuilder<List<Workout>>(
                          future: _getWorkouts(),
                          builder: (context, workoutsSnapshot) {
                            if (workoutsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final workouts = workoutsSnapshot.data ?? [];

                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rutinas Asignadas:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...assignedWorkouts.map((assigned) {
                                    final workout = workouts.firstWhere(
                                      (w) => w.id == assigned.workoutId,
                                      orElse:
                                          () => Workout(
                                            id: '',
                                            title: 'Rutina no encontrada',
                                            description: '',
                                            exercises: [],
                                          ),
                                    );
                                    return Dismissible(
                                      key: Key(assigned.id),
                                      background: Container(
                                        color: Colors.red.withOpacity(0.2),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      onDismissed: (direction) async {
                                        try {
                                          await _assignedWorkoutService
                                              .deleteAssignedWorkout(
                                                assigned.id,
                                              );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Rutina eliminada correctamente',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          setState(() {}); // Actualizar la UI
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error al eliminar la rutina: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      confirmDismiss: (direction) async {
                                        return await showDialog<bool>(
                                              context: context,
                                              builder:
                                                  (context) => Dialog(
                                                    backgroundColor:
                                                        const Color(0xFF2C2C2C),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            20,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .warning_rounded,
                                                            color:
                                                                Colors.orange,
                                                            size: 48,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          const Text(
                                                            '¿Eliminar rutina?',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            '¿Estás seguro de que deseas eliminar la rutina "${workout.title}" asignada a ${client.name}?',
                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white70,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 24,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            children: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child: const Text(
                                                                  'Cancelar',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Eliminar',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            ) ??
                                            false;
                                      },
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          workout.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nivel: ${workout.level ?? "No especificado"}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Text(
                                              'Asignada: ${_formatDate(assigned.assignedAt)}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(
                                          Icons.swipe_left,
                                          color: Colors.red,
                                          size: 16,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showWorkoutSelectionDialog(BuildContext context, User client) {
    return showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Seleccionar Rutina',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Workout>>(
                    future: _getWorkouts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF8C42),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }

                      final workouts = snapshot.data ?? [];

                      if (workouts.isEmpty) {
                        return const Text(
                          'No hay rutinas disponibles',
                          style: TextStyle(color: Colors.white70),
                        );
                      }

                      return SizedBox(
                        height: 300,
                        child: ListView.builder(
                          itemCount: workouts.length,
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            return Card(
                              color: Colors.white.withOpacity(0.05),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  workout.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nivel: ${workout.level ?? "No especificado"}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    if (workout.exercises.isNotEmpty)
                                      Text(
                                        '${workout.exercises.length} ejercicios',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  _assignWorkout(context, client, workout);
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Color(0xFFFF8C42)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
