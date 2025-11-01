import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/workout.dart';
import '../../../services/workout_service.dart';
import './create_workout_screen.dart';
import './workout_detail_screen.dart';
import './edit_workout_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final WorkoutService _workoutService = WorkoutService();
  Map<String, List<Workout>> _workoutsByDifficulty = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => _isLoading = true);
    try {
      final allWorkouts = await _workoutService.getAll();
      final Map<String, List<Workout>> workoutMap = {
        'Beginner': [],
        'Intermediate': [],
        'Advanced': [],
      };

      for (var workout in allWorkouts) {
        if (workout.level != null) {
          workoutMap[workout.level]?.add(workout);
        }
      }

      setState(() {
        _workoutsByDifficulty = workoutMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar las rutinas'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              'Confirmar eliminación',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              '¿Estás seguro que deseas eliminar la rutina ${workout.title}?',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _workoutService.deleteWorkout(workout.id);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadWorkouts();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rutina eliminada exitosamente'),
                          backgroundColor: Color(0xFFFF8C42),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al eliminar la rutina'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF8C42)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rutinas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFF8C42)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateWorkoutScreen(),
                ),
              );
              if (result == true) {
                _loadWorkouts();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF8C42),
        onRefresh: _loadWorkouts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._workoutsByDifficulty.entries.map((entry) {
                  final difficulty = entry.key;
                  final workouts = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            difficulty,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(
                                difficulty,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${workouts.length}',
                              style: TextStyle(
                                color: _getDifficultyColor(difficulty),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (workouts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'No hay rutinas de nivel $difficulty',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: workouts.length,
                          itemBuilder: (context, index) {
                            final workout = workouts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: Colors.white.withOpacity(0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _getDifficultyColor(
                                    difficulty,
                                  ),
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: Colors.white,
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => WorkoutDetailScreen(
                                            workoutId: workout.id,
                                          ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadWorkouts();
                                  }
                                },
                                title: Text(
                                  workout.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      '${workout.exercises.length} ejercicios',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      workout.description,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: _getDifficultyColor(difficulty),
                                  ),
                                  color: const Color(0xFF2A2A2A),
                                  itemBuilder:
                                      (context) => [
                                        PopupMenuItem(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            title: const Text(
                                              'Editar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 8,
                                            onTap: () async {
                                              Navigator.pop(context);
                                              final result =
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              EditWorkoutScreen(
                                                                workout:
                                                                    workout,
                                                              ),
                                                    ),
                                                  );
                                              if (result == true) {
                                                _loadWorkouts();
                                              }
                                            },
                                          ),
                                        ),
                                        PopupMenuItem(
                                          child: ListTile(
                                            leading: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            title: const Text(
                                              'Eliminar',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                            horizontalTitleGap: 8,
                                            onTap: () {
                                              Navigator.pop(context);
                                              _deleteWorkout(workout);
                                            },
                                          ),
                                        ),
                                      ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
