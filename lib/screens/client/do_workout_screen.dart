import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../../services/assigned_workout_service.dart';
import '../../utils/gym_context_helper.dart';

class DoWorkoutScreen extends StatefulWidget {
  final Workout workout;
  final List<Exercise> exercises;

  const DoWorkoutScreen({
    super.key,
    required this.workout,
    required this.exercises,
  });

  @override
  State<DoWorkoutScreen> createState() => _DoWorkoutScreenState();
}

class _DoWorkoutScreenState extends State<DoWorkoutScreen> {
  final _assignedWorkoutService = AssignedWorkoutService();
  int _currentIndex = 0;
  bool _finished = false;
  YoutubePlayerController? _youtubeController;
  bool _isLastExercise = false;

  // Timer related state
  Timer? _restTimer;
  int _restTimeInSeconds = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _isLastExercise = _currentIndex == widget.exercises.length - 1;
    _initializeYoutubeController(widget.exercises[_currentIndex].videoUrl);
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _youtubeController?.dispose();
    super.dispose();
  }

  String? _getYoutubeId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  void _initializeYoutubeController(String videoUrl) {
    _youtubeController?.dispose();
    final videoId = _getYoutubeId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          controlsVisibleAtStart: true,
        ),
      );
      setState(() {}); // Trigger rebuild to show video player
    } else {
      _youtubeController = null;
    }
  }

  Future<void> _completeWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🔥 Obtener contexto del gym
      final gymContext = context.gymContext;
      await _assignedWorkoutService.completeWorkout(
        user.uid,
        widget.workout.id,
        gymContext.gymId,
      );
      if (mounted) {
        setState(() {
          _finished = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al marcar la rutina como completada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousExercise() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isLastExercise = _currentIndex == widget.exercises.length - 1;
      });
      _initializeYoutubeController(widget.exercises[_currentIndex].videoUrl);
    }
  }

  bool _validateExerciseCompletion() {
    final exercise = widget.exercises[_currentIndex];
    final workoutExercise = widget.workout.exercises.firstWhere(
      (e) => e.exerciseId == exercise.id,
    );
    return true; // In the future, we could add validation for sets/reps completed
  }

  void _nextExercise() {
    if (_validateExerciseCompletion()) {
      if (_currentIndex < widget.exercises.length - 1) {
        setState(() {
          _currentIndex++;
          _isLastExercise = _currentIndex == widget.exercises.length - 1;
        });
        _initializeYoutubeController(widget.exercises[_currentIndex].videoUrl);
      } else {
        _completeWorkout();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa el ejercicio actual'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startRestTimer([int seconds = 60]) {
    setState(() {
      _isResting = true;
      _restTimeInSeconds = seconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restTimeInSeconds > 0) {
        setState(() {
          _restTimeInSeconds--;
        });
      } else {
        _stopRestTimer();
      }
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restTimeInSeconds = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRestButton(int seconds) {
    return OutlinedButton(
      onPressed: () => _startRestTimer(seconds),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFFF8C42)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        '${seconds}s',
        style: const TextStyle(
          color: Color(0xFFFF8C42),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_finished) return true;

    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text(
              '¿Abandonar Rutina?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Si sales ahora, perderás el progreso de esta rutina.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Salir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFF8C42),
                  size: 80,
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Felicidades!\nTerminaste la rutina',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Volver', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final exercise = widget.exercises[_currentIndex];
    final workoutExercise = widget.workout.exercises.firstWhere(
      (e) => e.exerciseId == exercise.id,
    );

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Ejercicio ${_currentIndex + 1} de ${widget.exercises.length}',
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFFF8C42)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child:
                    exercise.videoUrl.isNotEmpty && _youtubeController != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: YoutubePlayer(
                            controller: _youtubeController!,
                            showVideoProgressIndicator: true,
                            progressColors: const ProgressBarColors(
                              playedColor: Color(0xFFFF8C42),
                              handleColor: Color(0xFFFF8C42),
                            ),
                          ),
                        )
                        : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
              ),
              const SizedBox(height: 24),
              Text(
                exercise.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                exercise.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.refresh,
                              color: Color(0xFFFF8C42),
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${workoutExercise.sets} Series',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Icon(
                              Icons.fitness_center,
                              color: Color(0xFFFF8C42),
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${workoutExercise.repetitions} Reps',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_isResting) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Tiempo de Descanso: ${_formatTime(_restTimeInSeconds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _stopRestTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Terminar Descanso'),
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRestButton(30),
                          _buildRestButton(60),
                          _buildRestButton(90),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    ElevatedButton.icon(
                      onPressed: _previousExercise,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text(
                        'Anterior',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton.icon(
                    onPressed: _nextExercise,
                    icon: Icon(
                      _isLastExercise ? Icons.check : Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isLastExercise ? 'Finalizar' : 'Siguiente',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
