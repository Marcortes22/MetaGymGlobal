import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/workout.dart';
import '../../models/assigned_workout.dart';
import '../../services/assigned_workout_service.dart';
import '../../services/workout_service.dart';
import 'workout_details_screen.dart';

class ClientProgressScreen extends StatefulWidget {
  const ClientProgressScreen({super.key});

  @override
  State<ClientProgressScreen> createState() => _ClientProgressScreenState();
}

class _ClientProgressScreenState extends State<ClientProgressScreen> {
  final _assignedWorkoutService = AssignedWorkoutService();
  final _workoutService = WorkoutService();
  List<Map<String, dynamic>> _completedWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedWorkouts();
  }

  Future<void> _loadCompletedWorkouts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final assignedWorkouts = await _assignedWorkoutService.getByUser(user.uid);
        final completedWorkouts = [];

        for (final assigned in assignedWorkouts) {
          if (assigned.status == 'completed') {
            final workout = await _workoutService.getById(assigned.workoutId);
            if (workout != null) {
              completedWorkouts.add({
                'workout': workout,
                'completedAt': assigned.assignedAt,
              });
            }
          }
        }

        setState(() {
          _completedWorkouts = List<Map<String, dynamic>>.from(completedWorkouts);
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al cargar el progreso'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  AssetImage _getWorkoutImage(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('full') || lowerTitle.contains('completo')) {
      return const AssetImage('assets/workouts/full_body.jpg');
    } else if (lowerTitle.contains('upper') || lowerTitle.contains('superior')) {
      return const AssetImage('assets/workouts/upper_body.jpg');
    } else if (lowerTitle.contains('core') || lowerTitle.contains('abs')) {
      return const AssetImage('assets/workouts/core.jpg');
    } else if (lowerTitle.contains('cardio')) {
      return const AssetImage('assets/workouts/cardio.jpg');
    } else if (lowerTitle.contains('strength') || lowerTitle.contains('fuerza')) {
      return const AssetImage('assets/workouts/strength.jpg');
    }
    return const AssetImage('assets/workouts/full_body.jpg');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C42)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mi Progreso',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _completedWorkouts.isEmpty
          ? const Center(
              child: Text(
                'No has completado ninguna rutina todavía',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _completedWorkouts.length,
              itemBuilder: (context, index) {
                final item = _completedWorkouts[index];
                final workout = item['workout'] as Workout;
                final completedAt = item['completedAt'] as DateTime;

                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image(
                          image: _getWorkoutImage(workout.title),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
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
                              const SizedBox(height: 8),
                              Text(
                                'Completada el ${completedAt.day}/${completedAt.month}/${completedAt.year}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                workout.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
