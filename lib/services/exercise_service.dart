import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class ExerciseService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'exercises',
  );

  // 🔥 ACTUALIZADO - Obtener ejercicios por gym
  Future<List<Exercise>> getAll(String gymId) async {
    final snapshot = await _collection.where('gymId', isEqualTo: gymId).get();
    return snapshot.docs
        .map(
          (doc) => Exercise.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Exercise?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Exercise.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // 🔥 ACTUALIZADO - Crear ejercicio con gymId
  Future<Exercise> createExercise({
    required String gymId,
    required String name,
    required String muscleGroupId,
    required String equipment,
    required String difficulty,
    required String videoUrl,
    required String description,
  }) async {
    // Crear el mapa de datos del ejercicio
    final exerciseData = {
      'gymId': gymId, // 🔥 NUEVO
      'name': name,
      'muscleGroupId': muscleGroupId,
      'equipment': equipment,
      'difficulty': difficulty,
      'videoUrl': videoUrl,
      'description': description,
    };

    // Añadir el documento a Firestore
    final docRef = await _collection.add(exerciseData);

    // Obtener el ID del documento creado
    final String id = docRef.id;

    // Retornar el objeto Exercise
    return Exercise(
      id: id,
      gymId: gymId, // 🔥 NUEVO
      name: name,
      muscleGroupId: muscleGroupId,
      equipment: equipment,
      difficulty: difficulty,
      videoUrl: videoUrl,
      description: description,
    );
  }

  Future<Exercise> updateExercise(Exercise exercise) async {
    await _collection.doc(exercise.id).update(exercise.toMap());
    return exercise;
  }

  Future<void> deleteExercise(String id) async {
    await _collection.doc(id).delete();
  }

  // 🔥 NUEVO - Buscar ejercicios por grupo muscular
  Future<List<Exercise>> getByMuscleGroup(
    String gymId,
    String muscleGroupId,
  ) async {
    final snapshot =
        await _collection
            .where('gymId', isEqualTo: gymId)
            .where('muscleGroupId', isEqualTo: muscleGroupId)
            .get();
    return snapshot.docs
        .map(
          (doc) => Exercise.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }
}
