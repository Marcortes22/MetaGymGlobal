import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class.dart';

class ClassService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'classes',
  );

  // 🔥 ACTUALIZADO - Obtener clases por gym
  Future<List<GymClass>> getAll(String gymId) async {
    final snapshot = await _collection.where('gymId', isEqualTo: gymId).get();
    return snapshot.docs
        .map(
          (doc) => GymClass.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 NUEVO - Obtener clase por ID
  Future<GymClass?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return GymClass.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // 🔥 NUEVO - Crear clase
  Future<String> createClass(GymClass gymClass) async {
    final docRef = await _collection.add(gymClass.toMap());
    return docRef.id;
  }

  // 🔥 NUEVO - Actualizar clase
  Future<void> updateClass(String id, GymClass gymClass) async {
    await _collection.doc(id).update(gymClass.toMap());
  }

  // 🔥 NUEVO - Eliminar clase
  Future<void> deleteClass(String id) async {
    await _collection.doc(id).delete();
  }

  // 🔥 NUEVO - Obtener clases por instructor
  Future<List<GymClass>> getByInstructor(
    String instructorId,
    String gymId,
  ) async {
    final snapshot =
        await _collection
            .where('gymId', isEqualTo: gymId)
            .where('instructorId', isEqualTo: instructorId)
            .get();
    return snapshot.docs
        .map(
          (doc) => GymClass.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  // 🔥 NUEVO - Agregar asistente a clase
  Future<void> addAttendee(String classId, String userId) async {
    await _collection.doc(classId).update({
      'attendees': FieldValue.arrayUnion([userId]),
    });
  }

  // 🔥 NUEVO - Remover asistente de clase
  Future<void> removeAttendee(String classId, String userId) async {
    await _collection.doc(classId).update({
      'attendees': FieldValue.arrayRemove([userId]),
    });
  }
}
