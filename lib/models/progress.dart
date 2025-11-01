class Progress {
  final String id;
  final String userId;
  final String exerciseId;
  final DateTime date;
  final int setsCompleted;
  final int repetitionsAchieved;
  final double weightLiftedKg;
  final double bodyWeightKg;
  final String? notes;

  Progress({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.date,
    required this.setsCompleted,
    required this.repetitionsAchieved,
    required this.weightLiftedKg,
    required this.bodyWeightKg,
    this.notes,
  });

  factory Progress.fromMap(String id, Map<String, dynamic> data) {
    return Progress(
      id: id,
      userId: data['userId'],
      exerciseId: data['exerciseId'],
      date: DateTime.parse(data['date']),
      setsCompleted: data['setsCompleted'],
      repetitionsAchieved: data['repetitionsAchieved'],
      weightLiftedKg: (data['weightLiftedKg'] as num).toDouble(),
      bodyWeightKg: (data['bodyWeightKg'] as num).toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'date': date.toIso8601String(),
      'setsCompleted': setsCompleted,
      'repetitionsAchieved': repetitionsAchieved,
      'weightLiftedKg': weightLiftedKg,
      'bodyWeightKg': bodyWeightKg,
      'notes': notes,
    };
  }
}
