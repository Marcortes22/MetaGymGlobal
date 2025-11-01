import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/workout.dart';
import '../../services/assigned_workout_service.dart';
import '../../services/workout_service.dart';
import 'workout_details_screen.dart';

class ClientWorkoutsScreen extends StatefulWidget {
  const ClientWorkoutsScreen({super.key});

  @override
  State<ClientWorkoutsScreen> createState() => _ClientWorkoutsScreenState();
}

class _ClientWorkoutsScreenState extends State<ClientWorkoutsScreen> {
  final _assignedWorkoutService = AssignedWorkoutService();
  final _workoutService = WorkoutService();
  Future<List<Workout>>? _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _workoutsFuture = _getWorkouts(user.uid);
      });
    }
  }

  Future<List<Workout>> _getWorkouts(String userId) async {
    final assignedWorkouts = await _assignedWorkoutService.getByUser(userId);
    final workouts = <Workout>[];

    for (var assigned in assignedWorkouts) {
      final workout = await _workoutService.getById(assigned.workoutId);
      if (workout != null) {
        workouts.add(workout);
      }
    }
    return workouts;
  }

  AssetImage _getWorkoutImage(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('full') || lowerTitle.contains('completo')) {
      return const AssetImage('assets/memberships/premium.jpg');
    } else if (lowerTitle.contains('upper') || lowerTitle.contains('superior')) {
      return const AssetImage('assets/memberships/medium.jpg');
    } else if (lowerTitle.contains('core') || lowerTitle.contains('abs')) {
      return const AssetImage('assets/memberships/basic.jpg');
    } else if (lowerTitle.contains('cardio')) {
      return const AssetImage('assets/memberships/premium.jpg');
    } else if (lowerTitle.contains('strength') || lowerTitle.contains('fuerza')) {
      return const AssetImage('assets/memberships/medium.jpg');
    }
    return const AssetImage('assets/memberships/basic.jpg');
  }

  Widget _buildWorkoutStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: const Color(0xFFFF8C42),
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFF8C42)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFFF8C42)),
            onPressed: () {
              Navigator.pushNamed(context, '/user-profile');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Workout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center,
                    color: Color(0xFFFF8C42),
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes rutinas asignadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailsScreen(
                        workout: workout,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'workout-${workout.id}',
                  child: Container(
                    width: double.infinity,
                    height: 280,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[900],
                      image: DecorationImage(
                        image: _getWorkoutImage(workout.title),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.3),
                          BlendMode.darken,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ), // ← Cierra la propiedad `decoration` con coma

                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            workout.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _buildWorkoutStat(
                                Icons.access_time_rounded,
                                '${workout.exercises.length * 15}',
                                'Minutos',
                              ),
                              const SizedBox(width: 24),
                              _buildWorkoutStat(
                                Icons.fitness_center,
                                '${workout.exercises.length}',
                                'Ejercicios',
                              ),
                              const Spacer(),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WorkoutDetailsScreen(
                                          workout: workout,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF8C42),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF8C42)
                                              .withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Comenzar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ), // ← Cierra el child interno (Container con gradient y padding)
                  ), // ← Cierra el Container principal
                ),
              );
            },
          );
        },
      ),
    );
  }
}
