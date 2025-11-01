import 'package:flutter/material.dart';
import '../../../models/muscle_group.dart';
import '../../../services/exercise_service.dart';
import '../../../services/muscle_groups_service.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _exerciseService = ExerciseService();
  final _muscleGroupService = MuscleGroupService();

  String _name = '';
  String? _selectedMuscleGroup;
  String _equipment = '';
  String _selectedDifficulty = 'Beginner';
  String _videoUrl = '';
  String _description = '';
  bool _isLoading = false;
  List<MuscleGroup> _muscleGroups = [];

  final List<String> _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void initState() {
    super.initState();
    _loadMuscleGroups();
  }

  Future<void> _loadMuscleGroups() async {
    _muscleGroupService.getMuscleGroups().listen((groups) {
      setState(() {
        _muscleGroups = groups;
        if (groups.isNotEmpty && _selectedMuscleGroup == null) {
          _selectedMuscleGroup = groups.first.id;
        }
      });
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMuscleGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un grupo muscular'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _formKey.currentState!.save();

      await _exerciseService.createExercise(
        name: _name,
        muscleGroupId: _selectedMuscleGroup!,
        equipment: _equipment,
        difficulty: _selectedDifficulty,
        videoUrl: _videoUrl,
        description: _description,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ejercicio creado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear ejercicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          'Crear Ejercicio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre del ejercicio',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF8C42)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un nombre';
                    }
                    return null;
                  },
                  onSaved: (value) => _name = value!.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedMuscleGroup,
                  decoration: const InputDecoration(
                    labelText: 'Grupo Muscular',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF8C42)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  items:
                      _muscleGroups.map((group) {
                        return DropdownMenuItem(
                          value: group.id,
                          child: Text(
                            group.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMuscleGroup = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Equipo necesario',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF8C42)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el equipo necesario';
                    }
                    return null;
                  },
                  onSaved: (value) => _equipment = value!.trim(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedDifficulty,
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
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  items:
                      _difficulties.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(
                            difficulty,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDifficulty = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'URL del video (YouTube)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFFF8C42)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la URL del video';
                    }
                    if (!value.contains('youtube.com') &&
                        !value.contains('youtu.be')) {
                      return 'Por favor ingresa una URL válida de YouTube';
                    }
                    return null;
                  },
                  onSaved: (value) => _videoUrl = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
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
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una descripción';
                    }
                    return null;
                  },
                  onSaved: (value) => _description = value!.trim(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Crear Ejercicio',
                              style: TextStyle(
                                color: Colors.white,
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
