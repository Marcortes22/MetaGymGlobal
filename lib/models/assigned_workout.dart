class AssignedWorkout {
  final String id;
  final String userId;
  final String workoutId;
  final DateTime assignedAt;
  final String status;
  final String? notes;

  AssignedWorkout({
    required this.id,
    required this.userId,
    required this.workoutId,
    required this.assignedAt,
    required this.status,
    this.notes,
  });

  factory AssignedWorkout.fromMap(String id, Map<String, dynamic> data) {
    return AssignedWorkout(
      id: id,
      userId: data['userId'],
      workoutId: data['workoutId'],
      assignedAt: DateTime.parse(data['assignedAt']),
      status: data['status'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'assignedAt': assignedAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
