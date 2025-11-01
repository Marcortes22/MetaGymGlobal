import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../models/exercise.dart';
import '../../../services/exercise_service.dart';
import '../../../services/muscle_groups_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final MuscleGroupService _muscleGroupsService = MuscleGroupService();
  YoutubePlayerController? _youtubeController;

  Exercise? _exercise;
  String _muscleName = '';

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  String? _getYoutubeId(String url) {
    return YoutubePlayer.convertUrlToId(url);
  }

  void _initializeYoutubeController(String videoUrl) {
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
    }
  }

  Future<void> _loadExercise() async {
    final exercise = await _exerciseService.getById(widget.exerciseId);
    if (exercise != null) {
      final muscleGroup = await _muscleGroupsService.getMuscleGroup(
        exercise.muscleGroupId,
      );
      setState(() {
        _exercise = exercise;
        _muscleName = muscleGroup?.name ?? 'No especificado';
      });
      if (exercise.videoUrl.isNotEmpty) {
        _initializeYoutubeController(exercise.videoUrl);
      }
    }
  }

  Widget _buildVideoSection() {
    if (_exercise == null || _exercise!.videoUrl.isEmpty)
      return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Video Tutorial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (_youtubeController != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: Color(0xFFFF8C42),
                handleColor: Color(0xFFFF8C42),
              ),
              onReady: () {
                print('Player is ready.');
              },
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'No se pudo cargar el video',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
      ],
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
    if (_exercise == null) {
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
        title: Text(
          _exercise!.name,
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
              // Tarjeta de dificultad, grupo muscular y equipo
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
                    // Dificultad
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: _getDifficultyColor(_exercise!.difficulty),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _exercise!.difficulty,
                          style: TextStyle(
                            color: _getDifficultyColor(_exercise!.difficulty),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Grupo Muscular
                    _detailRow(
                      icon: Icons.sports_gymnastics,
                      label: 'Grupo Muscular',
                      value: _muscleName,
                    ),
                    const SizedBox(height: 12),
                    // Equipo
                    _detailRow(
                      icon: Icons.fitness_center,
                      label: 'Equipo',
                      value: _exercise!.equipment,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Título "Descripción"
              const Text(
                'Descripción',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Contenedor con descripción
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _exercise!.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              // Sección del video tutorial
              _buildVideoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
