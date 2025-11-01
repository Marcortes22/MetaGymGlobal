import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/muscle_group.dart';

class MuscleGroupService {
  final _collection = FirebaseFirestore.instance.collection('muscle_groups');

  // Crear
  Future<void> addMuscleGroup(MuscleGroup group) async {
    await _collection.doc(group.id).set(group.toMap(), SetOptions(merge: true));
  }

  // Leer todos
  Stream<List<MuscleGroup>> getMuscleGroups() {
    return _collection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => MuscleGroup.fromDocument(doc.id, doc.data()))
              .toList(),
    );
  }

  // Leer uno
  Future<MuscleGroup?> getMuscleGroup(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return MuscleGroup.fromDocument(doc.id, doc.data()!);
    }
    return null;
  }

  // Actualizar
  Future<void> updateMuscleGroup(MuscleGroup group) async {
    await _collection.doc(group.id).update(group.toMap());
  }

  // Eliminar
  Future<void> deleteMuscleGroup(String id) async {
    await _collection.doc(id).delete();
  }
}
