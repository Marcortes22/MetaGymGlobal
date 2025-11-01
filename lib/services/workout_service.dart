import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';

class WorkoutService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'workouts',
  );

  Future<Workout?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<List<Workout>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map(
          (doc) => Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<Workout>> getByDifficulty(String level) async {
    final snapshot = await _collection.where('level', isEqualTo: level).get();
    return snapshot.docs
        .map(
          (doc) => Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Workout> createWorkout({
    required String title,
    required String description,
    required List<WorkoutExercise> exercises,
    required String createdBy,
    required String level,
  }) async {
    final workoutData = {
      'title': title,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'level': level,
    };

    final docRef = await _collection.add(workoutData);
    return Workout(
      id: docRef.id,
      title: title,
      description: description,
      exercises: exercises,
      createdBy: createdBy,
      level: level,
    );
  }

  Future<void> updateWorkout(Workout workout) async {
    await _collection.doc(workout.id).update(workout.toMap());
  }

  Future<void> deleteWorkout(String id) async {
    await _collection.doc(id).delete();
  }
}
