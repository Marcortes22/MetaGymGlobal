import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/workout.dart';
import '../../../models/exercise.dart';
import '../../../services/workout_service.dart';
import '../../../services/exercise_service.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workoutService = WorkoutService();
  final _exerciseService = ExerciseService();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedDifficulty = 'Beginner';
  List<Exercise> _availableExercises = [];
  List<Map<String, dynamic>> _selectedExercises = [];

  final List<String> _difficultyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await _exerciseService.getAll();
      setState(() {
        _availableExercises = exercises;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cargar los ejercicios'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addExercise() async {
    final selectedExercise = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        Exercise? exercise;
        int sets = 3;
        int repetitions = 12;

        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Agregar Ejercicio',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Exercise>(
                      dropdownColor: const Color(0xFF2A2A2A),
                      value: exercise,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ejercicio',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF8C42)),
                        ),
                      ),
                      items:
                          _availableExercises
                              .map(
                                (e) => DropdownMenuItem<Exercise>(
                                  value: e,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setState(() {
                          exercise = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Series',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (sets > 1) sets--;
                                      });
                                    },
                                  ),
                                  Text(
                                    '$sets',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        sets++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Repeticiones',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (repetitions > 1) repetitions--;
                                      });
                                    },
                                  ),
                                  Text(
                                    '$repetitions',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        repetitions++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
              onPressed: () {
                if (exercise != null) {
                  Navigator.pop(context, {
                    'exercise': exercise,
                    'sets': sets,
                    'repetitions': repetitions,
                  });
                }
              },
              child: const Text(
                'Agregar',
                style: TextStyle(color: Color(0xFFFF8C42)),
              ),
            ),
          ],
        );
      },
    );

    if (selectedExercise != null) {
      setState(() {
        _selectedExercises.add(selectedExercise);
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un ejercicio a la rutina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final workoutExercises =
          _selectedExercises
              .map(
                (e) => WorkoutExercise(
                  exerciseId: (e['exercise'] as Exercise).id,
                  sets: e['sets'] as int,
                  repetitions: e['repetitions'] as int,
                ),
              )
              .toList();

      await _workoutService.createWorkout(
        title: _titleController.text,
        description: _descriptionController.text,
        exercises: workoutExercises,
        createdBy: user.uid,
        level: _selectedDifficulty,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Rutina creada exitosamente!'),
            backgroundColor: Color(0xFFFF8C42),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la rutina'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          'Crear Rutina',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF8C42)),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Título de la rutina',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF8C42)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un título';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          dropdownColor: const Color(0xFF2A2A2A),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Dificultad',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF8C42)),
                            ),
                          ),
                          items:
                              _difficultyLevels
                                  .map(
                                    (level) => DropdownMenuItem(
                                      value: level,
                                      child: Text(level),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDifficulty = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF8C42)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una descripción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
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
                            TextButton.icon(
                              onPressed: _addExercise,
                              icon: const Icon(
                                Icons.add,
                                color: Color(0xFFFF8C42),
                              ),
                              label: const Text(
                                'Agregar',
                                style: TextStyle(color: Color(0xFFFF8C42)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._selectedExercises.asMap().entries.map(
                          (entry) => Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                (entry.value['exercise'] as Exercise).name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${entry.value['sets']} series x ${entry.value['repetitions']} repeticiones',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeExercise(entry.key),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveWorkout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8C42),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isLoading ? 'Guardando...' : 'Guardar Rutina',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
