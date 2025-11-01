import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class.dart';

class ClassService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'classes',
  );

  Future<List<GymClass>> getAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map(
          (doc) => GymClass.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }
}
