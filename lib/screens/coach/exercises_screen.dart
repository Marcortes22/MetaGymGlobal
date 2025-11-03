import 'package:flutter/material.dart';
import '../../../models/exercise.dart';
import '../../../models/muscle_group.dart';
import '../../../services/exercise_service.dart';
import '../../../services/muscle_groups_service.dart';
import '../../../utils/gym_context_helper.dart';
import './exercise_detail_screen.dart';
import './create_exercise_screen.dart';
import './edit_exercise_screen.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final MuscleGroupService _muscleGroupService = MuscleGroupService();
  Map<String, List<Exercise>> _exercisesByMuscleGroup = {};
  List<MuscleGroup> _muscleGroups = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _setupMuscleGroupsListener();
  }

  void _setupMuscleGroupsListener() {
    _muscleGroupService.getMuscleGroups().listen((groups) {
      setState(() {
        _muscleGroups = groups;
      });
      _loadExercises();
    });
  }

  Future<void> _loadExercises() async {
    // 🔥 Obtener contexto del gym
    final gymContext = context.gymContext;
    final exercises = await _exerciseService.getAll(gymContext.gymId);

    final newExercisesByMuscleGroup = <String, List<Exercise>>{};

    // Inicializar las listas para cada grupo muscular
    for (var group in _muscleGroups) {
      newExercisesByMuscleGroup[group.id] = [];
    }

    // Distribuir los ejercicios en sus grupos musculares
    for (var exercise in exercises) {
      if (newExercisesByMuscleGroup.containsKey(exercise.muscleGroupId)) {
        newExercisesByMuscleGroup[exercise.muscleGroupId]!.add(exercise);
      }
    }

    setState(() {
      _exercisesByMuscleGroup = newExercisesByMuscleGroup;
    });
  }

  Future<void> _navigateToCreateExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
    );
    if (result == true) {
      _loadExercises();
    }
  }

  Future<void> _navigateToEditExercise(Exercise exercise) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExerciseScreen(exercise: exercise),
      ),
    );
    if (result == true) {
      _loadExercises();
    }
  }

  Future<void> _deleteExercise(Exercise exercise) async {
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
              '¿Estás seguro que deseas eliminar el ejercicio ${exercise.name}?',
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
                    await _exerciseService.deleteExercise(exercise.id);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadExercises();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ejercicio eliminado exitosamente'),
                          backgroundColor: Color(0xFFFF8C42),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al eliminar el ejercicio'),
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
          'Ejercicios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFF8C42)),
            onPressed: _navigateToCreateExercise,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _muscleGroups.map((muscleGroup) {
                  final exercises =
                      _exercisesByMuscleGroup[muscleGroup.id] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            muscleGroup.name,
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
                              color: const Color(0xFFFF8C42).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${exercises.length}',
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
                      if (exercises.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text(
                            'No hay ejercicios para ${muscleGroup.name}',
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
                          itemCount: exercises.length,
                          itemBuilder: (context, index) {
                            final exercise = exercises[index];
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ExerciseDetailScreen(
                                            exerciseId: exercise.id,
                                          ),
                                    ),
                                  );
                                },
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
                                      'Dificultad: ${exercise.difficulty}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      exercise.description,
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
                                    color: _getDifficultyColor(
                                      exercise.difficulty,
                                    ),
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
                                            onTap: () {
                                              Navigator.pop(context);
                                              _navigateToEditExercise(exercise);
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
                                              _deleteExercise(exercise);
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
          ),
        ),
      ),
    );
  }
}
