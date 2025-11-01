import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/workout.dart';
import '../../models/assigned_workout.dart';
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
            icon: const Icon(Icons.notifications, color: Color(0xFFFF8C42)),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return const Center(
              child: Text(
                'No tienes rutinas asignadas',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailsScreen(
                          workout: workouts.first,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: _getWorkoutImage(workouts.first.title),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.2),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C42),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Training Of The Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            workouts.first.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workouts.first.exercises.length * 15} Minutes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.fitness_center,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${workouts.first.exercises.length} Exercises',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Text(
                  'Otras Rutinas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                for (var workout in workouts.skip(1))
                  GestureDetector(
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
                    child: Container(
                      width: double.infinity,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: _getWorkoutImage(workout.title),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.2),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${workout.exercises.length * 15} Minutes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.fitness_center,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${workout.exercises.length} Exercises',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
