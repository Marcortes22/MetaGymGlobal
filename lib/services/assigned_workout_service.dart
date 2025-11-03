import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assigned_workout.dart';

class AssignedWorkoutService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'assigned_workouts',
  );

  // 🔥 ACTUALIZADO - Obtener asignaciones por usuario Y gym
  Future<List<AssignedWorkout>> getByUser(String userId, String gymId) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId)
            .get();
    return snapshot.docs
        .map(
          (doc) => AssignedWorkout.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AssignedWorkout> assignWorkout(AssignedWorkout workout) async {
    final doc = await _collection.add(workout.toMap());
    return AssignedWorkout.fromMap(doc.id, workout.toMap());
  }

  // 🔥 ACTUALIZADO - Completar workout con gymId
  Future<void> completeWorkout(
    String userId,
    String workoutId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('workoutId', isEqualTo: workoutId)
            .where('gymId', isEqualTo: gymId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await _collection.doc(doc.id).update({'status': 'completed'});
    }
  }

  // 🔥 ACTUALIZADO - Obtener asignaciones por workout Y gym
  Future<List<AssignedWorkout>> getByWorkout(
    String workoutId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('workoutId', isEqualTo: workoutId)
            .where('gymId', isEqualTo: gymId)
            .get();
    return snapshot.docs
        .map(
          (doc) => AssignedWorkout.fromMap(
            doc.id,
            doc.data() as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> deleteAssignedWorkout(String id) async {
    await _collection.doc(id).delete();
  }

  // 🔥 ACTUALIZADO - Verificar si workout está asignado (con gymId)
  Future<bool> isWorkoutAssigned(
    String userId,
    String workoutId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('workoutId', isEqualTo: workoutId)
            .where('gymId', isEqualTo: gymId)
            .get();
    return snapshot.docs.isNotEmpty;
  }
}
