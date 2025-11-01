import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/progress.dart';

class ProgressService {
  final CollectionReference _collection = FirebaseFirestore.instance.collection(
    'progress',
  );

  Future<List<Progress>> getByUser(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
    return snapshot.docs
        .map(
          (doc) => Progress.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }
}
