import 'package:flutter/material.dart';
import '../../../models/workout.dart';
import '../../../models/exercise.dart';
import '../../../services/workout_service.dart';
import '../../../services/exercise_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseService _exerciseService = ExerciseService();
  bool _isLoading = true;
  Workout? _workout;
  Map<String, Exercise> _exercises = {};

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    setState(() => _isLoading = true);
    try {
      final workout = await _workoutService.getById(widget.workoutId);
      if (workout != null) {
        // Cargar los ejercicios asociados
        final exerciseIds = workout.exercises.map((e) => e.exerciseId).toList();
        final exercises = await Future.wait(
          exerciseIds.map((id) => _exerciseService.getById(id)),
        );

        final exerciseMap = <String, Exercise>{};
        for (var exercise in exercises) {
          if (exercise != null) {
            exerciseMap[exercise.id] = exercise;
          }
        }

        setState(() {
          _workout = workout;
          _exercises = exerciseMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar la rutina'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (_workout == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            'No se encontró la rutina',
            style: TextStyle(color: Colors.white),
          ),
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
        title: Text(
          _workout!.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de información general
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: _getDifficultyColor(_workout!.level ?? ''),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _workout!.level ?? 'Sin nivel',
                          style: TextStyle(
                            color: _getDifficultyColor(_workout!.level ?? ''),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _workout!.description,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Lista de ejercicios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ejercicios',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_workout!.exercises.length}',
                      style: const TextStyle(
                        color: Color(0xFFFF8C42),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _workout!.exercises.length,
                itemBuilder: (context, index) {
                  final workoutExercise = _workout!.exercises[index];
                  final exercise = _exercises[workoutExercise.exerciseId];

                  if (exercise == null) return const SizedBox();

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
                          exercise.difficulty,
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        exercise.name,
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
                            '${workoutExercise.sets} series x ${workoutExercise.repetitions} repeticiones',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Equipo: ${exercise.equipment}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
