class Exercise {
  final String id;
  final String name;
  final String muscleGroupId;
  final String equipment;
  final String difficulty;
  final String videoUrl;
  final String description;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroupId,
    required this.equipment,
    required this.difficulty,
    required this.videoUrl,
    required this.description,
  });

  factory Exercise.fromMap(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      name: data['name'],
      muscleGroupId: data['muscleGroupId'],
      equipment: data['equipment'],
      difficulty: data['difficulty'],
      videoUrl: data['videoUrl'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'muscleGroupId': muscleGroupId,
      'equipment': equipment,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'description': description,
    };
  }
}
