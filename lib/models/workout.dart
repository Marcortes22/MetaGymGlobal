class Workout {
  final String id;
  final String title;
  final String description;
  final List<WorkoutExercise> exercises;
  final String? createdBy;
  final String? level;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.exercises,
    this.createdBy,
    this.level,
  });

  factory Workout.fromMap(String id, Map<String, dynamic> data) {
    return Workout(
      id: id,
      title: data['title'],
      description: data['description'],
      exercises:
          List<Map<String, dynamic>>.from(
            data['exercises'],
          ).map((e) => WorkoutExercise.fromMap(e)).toList(),
      createdBy: data['createdBy'],
      level: data['level'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'level': level,
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final int repetitions;
  final int sets;

  WorkoutExercise({
    required this.exerciseId,
    required this.repetitions,
    required this.sets,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> data) {
    return WorkoutExercise(
      exerciseId: data['exerciseId'],
      repetitions: data['repetitions'],
      sets: data['sets'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'exerciseId': exerciseId, 'repetitions': repetitions, 'sets': sets};
  }
}
