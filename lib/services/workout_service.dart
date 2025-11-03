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

  // 🔥 ACTUALIZADO - Obtener workouts por gym
  Future<List<Workout>> getAll(String gymId) async {
    final snapshot = await _collection.where('gymId', isEqualTo: gymId).get();
    return snapshot.docs
        .map(
          (doc) => Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 ACTUALIZADO - Obtener workouts por dificultad Y gym
  Future<List<Workout>> getByDifficulty(String level, String gymId) async {
    final snapshot =
        await _collection
            .where('gymId', isEqualTo: gymId)
            .where('level', isEqualTo: level)
            .get();
    return snapshot.docs
        .map(
          (doc) => Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 ACTUALIZADO - Crear workout con gymId
  Future<Workout> createWorkout({
    required String gymId,
    required String title,
    required String description,
    required List<WorkoutExercise> exercises,
    required String createdBy,
    required String level,
  }) async {
    final workoutData = {
      'gymId': gymId, // 🔥 NUEVO
      'title': title,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdBy': createdBy,
      'level': level,
    };

    final docRef = await _collection.add(workoutData);
    return Workout(
      id: docRef.id,
      gymId: gymId, // 🔥 NUEVO
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

  // 🔥 NUEVO - Obtener workouts creados por un entrenador específico
  Future<List<Workout>> getByCreator(String creatorId, String gymId) async {
    final snapshot =
        await _collection
            .where('gymId', isEqualTo: gymId)
            .where('createdBy', isEqualTo: creatorId)
            .get();
    return snapshot.docs
        .map(
          (doc) => Workout.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }
}
