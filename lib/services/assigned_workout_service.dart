import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assigned_workout.dart';

class AssignedWorkoutService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'assigned_workouts',
  );
  Future<List<AssignedWorkout>> getByUser(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
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

  Future<void> completeWorkout(String userId, String workoutId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('workoutId', isEqualTo: workoutId)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      await _collection.doc(doc.id).update({'status': 'completed'});
    }
  }

  Future<List<AssignedWorkout>> getByWorkout(String workoutId) async {
    final snapshot =
        await _collection.where('workoutId', isEqualTo: workoutId).get();
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

  Future<bool> isWorkoutAssigned(String userId, String workoutId) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('workoutId', isEqualTo: workoutId)
            .get();
    return snapshot.docs.isNotEmpty;
  }
}
