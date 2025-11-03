import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress.dart';

class ProgressService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'progress',
  );

  // 🔥 ACTUALIZADO - Obtener progreso por usuario Y gym
  Future<List<Progress>> getByUser(String userId, String gymId) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('gymId', isEqualTo: gymId)
            .get();
    return snapshot.docs
        .map(
          (doc) => Progress.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 NUEVO - Crear registro de progreso
  Future<String> createProgress(Progress progress) async {
    final docRef = await _collection.add(progress.toMap());
    return docRef.id;
  }

  // 🔥 NUEVO - Obtener progreso por ejercicio específico
  Future<List<Progress>> getByExercise(
    String userId,
    String exerciseId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('exerciseId', isEqualTo: exerciseId)
            .where('gymId', isEqualTo: gymId)
            .orderBy('date', descending: true)
            .get();
    return snapshot.docs
        .map(
          (doc) => Progress.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 NUEVO - Obtener último progreso de un ejercicio
  Future<Progress?> getLatestProgressForExercise(
    String userId,
    String exerciseId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('userId', isEqualTo: userId)
            .where('exerciseId', isEqualTo: exerciseId)
            .where('gymId', isEqualTo: gymId)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return null;
    return Progress.fromMap(
      snapshot.docs.first.id,
      snapshot.docs.first.data() as Map<String, dynamic>,
    );
  }

  // 🔥 NUEVO - Eliminar registro de progreso
  Future<void> deleteProgress(String id) async {
    await _collection.doc(id).delete();
  }
}
